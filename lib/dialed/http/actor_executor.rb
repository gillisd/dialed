module Dialed
  module HTTP
    class ActorExecutor
      class RequestTimeoutError < StandardError; end
      class ExecutorClosedError < StandardError; end

      DEFAULT_TIMEOUT = 30 # seconds

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

      def initialize(client = self.class.build_client)
        @client = client
        @running = true
        @mutex = Mutex.new
        @cv = ConditionVariable.new
        @requests = []

        # Start the main processing thread
        @thread = Thread.new do
          Async do |task|
            while @running || !@requests.empty?
              # Get next batch of requests
              current_batch = nil
              @mutex.synchronize do
                current_batch = @requests.dup
                @requests.clear
              end

              # Process all current requests in parallel
              if current_batch && !current_batch.empty?
                tasks = current_batch.map do |req_data|
                  task.async do
                    id, args, kwargs, result_queue = req_data
                    begin
                      response = @client.get(*args, **kwargs)
                      result_queue.push([:response, response])
                    rescue => e
                      result_queue.push([:error, e])
                    end
                  end
                end

                # Wait for all requests in this batch to complete
                tasks.each(&:wait)
              else
                # No requests, wait a bit
                sleep 0.01
              end
            end

            @client.close
          end
        end
      end

      def close
        return unless @running
        @running = false
        @thread.join(5)
        @thread.kill if @thread.alive?
      end

      def get(*args, timeout: DEFAULT_TIMEOUT, **kwargs)
        raise ExecutorClosedError, "Executor has been closed" unless @running

        result_queue = Queue.new
        request_id = rand(10000)

        # Add the request to the processing queue
        @mutex.synchronize do
          @requests << [request_id, args, kwargs, result_queue]
          @cv.signal
        end

        # Wait for the result with timeout
        begin
          status, result = Timeout.timeout(timeout) do
            result_queue.pop
          end

          if status == :error
            raise result
          else
            return result
          end
        rescue Timeout::Error
          raise RequestTimeoutError, "Request timed out after #{timeout} seconds"
        end
      end

      def running?
        @running
      end
    end
  end
end