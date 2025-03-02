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
          block.binding.local_variable_set(:client, self)

          instance_exec(caller_yielder, &block)

          Enumerator::Lazy.new(futures) do |yielder, *future_arr|
            future_arr.each do |future|
              if future.respond_to?(:value!)
                yielder << future.value!
              elsif future.respond_to?(:wait)
                future.wait
                yielder << future.result
              else
                raise "Unknown future type: #{future.class}"
              end
            end
          end
        ensure
          # Ensure it's changed back to the real, unproxied client
          block.binding.local_variable_set(:client, @_client)
        end
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