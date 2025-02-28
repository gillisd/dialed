# frozen_string_literal: true

require 'async/waiter'
module Dialed
  module HTTP
    class Client
      def self.build(&)
        ExplicitClient.new create_connection_builder(&)
      end

      def self.create_connection_builder(&block)
        if block_given?
          connection_builder = ConnectionBuilder.new
          block.call(connection_builder)
          return connection_builder
        end
        ConnectionBuilder.apply_defaults
      end

      def close
        return if @closed

        @closed = true
        with_dialer(&:hangup!)
      end

      attr_accessor :waiter

      def initialize(connection_builder = ConnectionBuilder.apply_defaults)
        @connection_builder = connection_builder
        @async_task_count = 0
        @closed = false
      end

      def get(location, query: {}, **kwargs)
        with_dialer do |dialer|
          response = dialer.call('GET', location, **kwargs)
          response
        end
      end

      def async(&block)
        Async do |task|
          waiter = Async::Waiter.new(parent: task)
          waiting_client = dup
          waiting_client.waiter = waiter
          arr = []
          implicit = block.call(waiting_client, arr)
          if arr.empty?
            waiter.wait(waiter.instance_variable_get(:@done).count)
            implicit
          else
            enum = Enumerator::Lazy.new(arr) do |yielder, *values|
              if values.size == 1
                value = values.first
                value.wait
                yielder << value.result
              else
                values.each(&:wait)
                yielder << values.map(&:result)
              end
            end
            enum
          end
        end
      end

      attr_reader :connection_builder

      def with_dialer(&block)
        if waiter
          waiter.async do
            fetch_dialer(&block)
          end
        elsif Async::Task.current?
          fetch_dialer do |dialer|
            block.call(dialer)
          end
        else
          Sync do
            fetch_dialer do |dialer|
              dialer.start_session do |session|
                block.call(session)
              end
            end
          end
        end
      end
    end
  end
end
