module Dialed
  module HTTP
    class AsyncProxy
      def initialize(client)
        @_client = client
        @futures = []
      end

      def async(&block)
        begin
          futures = []
          caller_yielder = Enumerator::Yielder.new(&futures.method(:<<))

          # Need to change the value of "client" to self in the block, as instance_exec isn't overriding it.
          calling_client_varnames = block
                                      .binding
                                      .local_variables.select { block.binding.local_variable_get(_1) == @_client }

          raise "Unexpected number of client variables" unless calling_client_varnames.size == 1
          calling_client_varname = calling_client_varnames.first

          block.binding.local_variable_set(calling_client_varname, self)

          instance_exec(caller_yielder, &block)

          Enumerator::Lazy.new(futures) do |yielder, *future_arr|
            future_arr.each do |future|
              if future.respond_to?(:value!)
                yielder << future.value!
              elsif future.respond_to?(:wait)
                future.wait
                yielder << future.result
              elsif future.is_a?(Dialed::HTTP::Response)
                warn "A future was not produced - this means your async calls were synchronous"
                yielder << future
              else
                raise "Unknown future type: #{future.class}"
              end
            end
          end
        ensure
          # Ensure it's changed back to the real, unproxied client
          block.binding.local_variable_set(calling_client_varname, @_client)
        end
      end

      def client
        self
      end

      private

      def method_missing(method, *args, &block)
        super unless is_http_method?(method)
        @_client.executor.class.wrap_async do
          @_client.send(method, *args, &block)
        end
      end

      def respond_to_missing?(method, include_private = false)
        is_http_method?(method) || super
      end

      def is_http_method?(method)
        %i[get post put delete patch head options trace].include?(method)
      end
    end
  end
end