# frozen_string_literal: true

module Dialed
  module HTTP

    class Client
      attr_reader :configuration

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

      def close
        Kernel.with_warnings(nil) do
          operator.close
        end
      end

      def initialize(configuration = ConnectionBuilder.new.build)
        @configuration = configuration.freeze
      end

      def get(location, **kwargs, &block)
        uri = destination.uri_for(location)
        dialer = operator.get_dialer(uri, connection_configuration: configuration.connection_configuration)
        dialer.call('GET', uri.request_uri, **kwargs, &block)
      end

      private

      def operator
        # in explicit client, it gets its own operator
        Operator.instance
      end

      def destination
        @configuration.destination
      end
    end
  end
end
