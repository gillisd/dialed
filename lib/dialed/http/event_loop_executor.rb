module Dialed
  module HTTP
    class EventLoopExecutor
      def self.wrap_async(&block)
        Async(&block)
      end

      def call(executor_request)
        uri = executor_request.uri
        connection_configuration = executor_request.connection_configuration
        method = executor_request.method
        kwargs = executor_request.kwargs
        block = executor_request.block

        Kernel.with_warnings(nil) do
          Sync do
            operator
              .get_dialer(
                uri,
                connection_configuration: connection_configuration
              )
              .call(method, uri.request_uri, **kwargs, &block)
          end
        end
      end

      def close
        Sync do
          Kernel.with_warnings(nil) do
            operator.close
          end
        end
      end

      private

      def operator
        # in explicit client, it gets its own operator
        Operator.instance
      end
    end
  end
end