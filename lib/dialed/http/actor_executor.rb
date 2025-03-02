module Dialed
  module HTTP
    class ActorExecutor
      class RequestTimeoutError < StandardError; end

      class ExecutorClosedError < StandardError; end

      DEFAULT_TIMEOUT = 30 # seconds

      def self.wrap_async
        Concurrent::Future.execute do
          yield
        end
      end

      def initialize
        @running = true
        @mutex = Mutex.new
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
                    request_id, executor_request, result_queue = req_data
                    begin
                      # response = @client.get(*args, **kwargs)
                      response = execute_request(executor_request)
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

            close
          end
        end
      end

      def close
        return unless @running
        operator.close
        @running = false
        @thread.join(5)
        @thread.kill if @thread.alive?
      end

      def call(executor_request)
        timeout = DEFAULT_TIMEOUT
        raise ExecutorClosedError, "Executor has been closed" unless @running

        result_queue = Queue.new
        request_id = SecureRandom.uuid

        # Add the request to the processing queue
        @mutex.synchronize do
          @requests << [request_id, executor_request, result_queue]
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

      private

      def operator
        # in explicit client, it gets its own operator
        Operator.instance
      end

      def execute_request(executor_request)
        uri = executor_request.uri
        connection_configuration = executor_request.connection_configuration
        method = executor_request.method
        kwargs = executor_request.kwargs
        block = executor_request.block

        operator
          .get_dialer(
            uri,
            connection_configuration: connection_configuration
          )
          .call(method, uri.request_uri, **kwargs, &block)
      end
    end
  end
end