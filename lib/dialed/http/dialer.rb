# frozen_string_literal: true

module Dialed
  module HTTP
    class Dialer
      attr_reader :connection

      def initialize(builder = ConnectionBuilder.apply_defaults, lazy: true, &block)
        @builder = builder
        @connection = NilConnection.new
        @lazy = lazy
        start_session(&block) if block_given?
      end

      def connected?
        connection.open?
      end

      def lazy?
        @lazy
      end

      def disconnected?
        connection.closed?
      end

      def current_host
        return nil unless on_a_call?

        connection.remote_host
      end

      def start_session(&block)
        attempt_connection!
        block.call(self)
      ensure
        hangup!
      end

      def call(verb, location, *args, proxy_uri: nil, **kwargs)
        location_uri = Addressable::URI.parse(location)
        request = Request.new(verb, location_uri.path, *args, **kwargs)
        response = (
          if connection.open?
            response = request.call(connection)
            Response.new(response)
          elsif lazy?
            @builder.uri = location_uri
            @builder.proxy_uri = proxy_uri if proxy_uri
            success = attempt_connection!
            raise Dialed::Error, "Failed to connect to #{location}. connection status: #{connection.open?}" unless success

            Response.new(request.call(connection))
          else
            success = attempt_connection!
            raise Dialed::Error, "Failed to connect to #{location}. connection status: #{connection.open?}" unless success

            Response.new(request.call(connection))
          end

        )

        return response unless block_given?

        begin
          yield response
        ensure
          response.close
        end
      end

      def hangup!
        connection.close if connection.open?
        @connection = NilConnection.new
      end

      def ready?
        raise 'Expected connection not to be actually nil' if connection.nil?
        return false if connection.nil_connection?
        return false if connection.open?
        return false unless @builder.valid?

        true
      end

      private

      def attempt_connection!
        return true if ready?

        @connection = @builder.build
        connection.connect
      end
    end
  end
end
