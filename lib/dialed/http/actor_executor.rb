module Dialed
  module HTTP
    class ActorExecutor
      class RequestTimeoutError < StandardError; end
      class ExecutorClosedError < StandardError; end
      class QueueFullError < StandardError; end

      DEFAULT_TIMEOUT = 30 # seconds
      DEFAULT_QUEUE_LIMIT = 100 # maximum pending requests

      def self.build_client
        Dialed::Client.build do |c|
          c.version = '2.0'
          c.host = 'httpbin.org'
          c.scheme = 'https'
          c.port = 443
          c.proxy do |p|
            p.host = 'localhost'
            p.port = 8899
          end
        end
      end

      def initialize(client = self.class.build_client, queue_limit: DEFAULT_QUEUE_LIMIT)
        @queue = Thread::Queue.new
        @running = true
        @client = client
        @queue_limit = queue_limit
        @current_queue_size = 0
        @queue_mutex = Mutex.new

        @thread = Thread.new do
          begin
            Async do |task|
              main_loop_task = task.async do
                while @running || !@queue.empty?
                  # Use timeout to avoid blocking indefinitely
                  payload = nil
                  if @running
                    payload = @queue.pop
                  else
                    # If we're shutting down, only check for remaining items
                    payload = @queue.pop if !@queue.empty?
                  end

                  break unless payload # nil is our shutdown signal

                  result_queue, obj, options = payload

                  # Decrement queue size after dequeuing
                  @queue_mutex.synchronize { @current_queue_size -= 1 }

                  begin
                    response = @client.get(*obj, **options)
                    result_queue.push([:response, response])
                  rescue => e
                    result_queue.push([:error, e])
                  end
                end

                task.stop
                @client.close
              end
              main_loop_task.wait
            end
          rescue => e
            # Log the error (replace with proper logging)
            STDERR.puts "Actor executor thread crashed: #{e.class} - #{e.message}\n#{e.backtrace.join("\n")}"
          ensure
            @running = false
          end
        end
      end

      def close
        return unless @running
        @running = false
        @queue.clear
        @queue_mutex.synchronize { @current_queue_size = 0 }
        @queue.push(nil) # Signal to shutdown
        @thread.join(5) # Wait up to 5 seconds for clean shutdown
        @thread.kill if @thread.alive? # Force termination if needed
      end

      def get(*args, timeout: DEFAULT_TIMEOUT, **kwargs)
        raise ExecutorClosedError, "Executor has been closed" unless @running

        # Check queue size limit
        @queue_mutex.synchronize do
          if @current_queue_size >= @queue_limit
            raise QueueFullError, "Request queue limit of #{@queue_limit} reached"
          end
          @current_queue_size += 1
        end

        result_queue = Queue.new
        begin
          @queue.push([result_queue, args, { timeout: timeout, **kwargs }])

          status, result = Timeout.timeout(timeout) do
            result_queue.pop
          end

          if status == :error
            raise result
          else
            return result
          end
        rescue Timeout::Error
          # If timeout occurs, decrement the queue size counter if the request was never processed
          # This is best-effort as we can't know for sure if the request was processed yet
          @queue_mutex.synchronize { @current_queue_size -= 1 } rescue nil
          raise RequestTimeoutError, "Request timed out after #{timeout} seconds"
        rescue => e
          # For any other exception, also try to decrement the counter
          @queue_mutex.synchronize { @current_queue_size -= 1 } rescue nil
          raise e
        end
      end

      def running?
        @running
      end

      def queue_size
        @queue_mutex.synchronize { @current_queue_size }
      end

      def queue_limit
        @queue_limit
      end
    end
  end
end