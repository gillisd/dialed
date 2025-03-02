# frozen_string_literal: true

module Dialed
  module HTTP
    ExecutorRequest = Data.define(:method, :uri, :connection_configuration, :kwargs, :block)

    class Client
      attr_reader :configuration, :executor

      def self.build(&block)
        new create_connection_builder(&block).build
      end

      def self.create_connection_builder(&block)
        if block_given?
          connection_builder = ConnectionBuilder.new
          block.call(connection_builder)
          return connection_builder
        end
        ConnectionBuilder.apply_defaults
      end

      def self.determine_executor
        if Async::Task.current?
          EventLoopExecutor.new
        else
          ActorExecutor.new
        end
      end

      def wait
        @executor.wait
      end

      def close
        @executor.close
      end

      def async(&block)
        AsyncProxy.new(self).async(&block)
      end

      def initialize(
        configuration = ConnectionBuilder.build_with_defaults,
        executor = self.class.determine_executor
      )
        @executor = executor
        @configuration = configuration.freeze
      end

      def get(location, **kwargs, &block)
        request = create_executor_request('GET', location, kwargs, block)
        @executor.call(request)
      end

      private

      def create_executor_request(method, location, kwargs, block)
        destination = configuration.destination
        connection_configuration = configuration.connection_configuration
        uri = destination.uri_for(location)
        ExecutorRequest.new(
          method: method,
          uri: uri,
          connection_configuration: connection_configuration,
          kwargs: kwargs,
          block: block
        )
      end
    end
  end
end
