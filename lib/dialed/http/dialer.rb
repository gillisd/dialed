# frozen_string_literal: true

module Dialed
  module HTTP
    class Dialer
      attr_reader :connection, :base_uri

      delegate :destination, to: :configuration

      attr_reader :configuration

      delegate :http1?, :http2?, to: :connection

      def initialize(base_uri, configuration:, &block)
        @semaphore = Async::Semaphore.new
        @base_uri = base_uri
        @configuration = configuration
        @connection = NilConnection.new
        start_session(&block) if block_given?
      end

      def connected?
        connection.open?
      end

      def disconnected?
        connection.closed?
      end

      def current_host
        return nil unless connected?

        connection.remote_host
      end

      def start_session(&block)
        attempt_connection!
        block.call(self)
      ensure
        hangup!
      end

      def connect
        attempt_connection!
      end

      def call(verb, path, *args, **kwargs)
        request = Request.new(verb, path, *args, **kwargs)
        response = (
          if connection.open?
            response = request.call(connection)
            Response.new(response)
          else
            success = attempt_connection!
            raise Dialed::Error, "Failed to connect to #{location}. connection status: #{connection.open?}" unless success

            Response.new(request.call(connection))
          end
        )

        if block_given?
          yield response
        else
          return response
        end
        response.close
      end

      def hangup!
        connection.close if connection.open?
        @connection = NilConnection.new
      end

      def ready?
        raise 'Expected connection not to be actually nil' if connection.nil?
        return false unless connection.ready?

        true
      end

      private

      def attempt_connection!
        return true if connection.open?
        return true if ready?

        @connection = Connection.from_configuration(@base_uri, configuration: configuration)
        @connection.connect
      end
    end
  end
end
