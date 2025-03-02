# frozen_string_literal: true

module Dialed
  module HTTP
    class Connection
      attr_reader :configuration, :remote_uri

      delegate :ssl_context, to: :configuration
      delegate :version, to: :configuration, prefix: :remote
      delegate :host, :port, to: :remote_host
      delegate :scheme, to: :remote_uri

      delegate :version, :http2?, :http1?, :ready?, to: :internal_connection
      delegate :call, to: :internal_connection

      alias remote_host remote_uri

      def self.from_configuration(remote_uri, configuration:)
        connection_klass = configuration.connection_klass
        connection_klass.new(remote_uri, configuration: configuration)
      end

      def initialize(remote_uri, configuration:)
        @remote_uri = remote_uri
        @configuration = configuration
      end

      def ping
        internal_connection.send_ping(SecureRandom.bytes(8))
      end

      def address
        "#{host}:#{port}"
      end

      def closed?
        return false if @internal_connection.nil?
        if http1?
          @internal_connection.stream.closed?
        else
          @internal_connection.closed?
        end
      end

      def open?
        return false if @internal_connection.nil?
        !closed?
      end

      def connect
        if @internal_connection.nil?
          @internal_connection = create_internal_connection
          return open?
        end
        return true if open?
        raise Dialed::Error, "Connection already closed" if closed?
        open?
      rescue StandardError => e
        raise e if e.is_a?(NilConnection::NilConnectionError)
        @internal_connection = NilConnection.new
        raise e
      end

      def nil_connection?
        false
      end

      def close
        raise NotImplementedError, 'Subclasses must implement close'
      end

      def authority
        # if we use remote_connection.authority it will always return the port with the URI.
        host
      end

      protected

      def create_internal_connection
        raise NotImplementedError, 'Subclasses must implement create_internal_connection'
      end


      private

      def internal_connection

        if  @internal_connection.nil?
          @internal_connection
        end
        @internal_connection
      end

      def async_http_protocol
        case remote_version
        in :h2 then Async::HTTP::Protocol::HTTP2
        in :http11 | :http10 | :http1 then Async::HTTP::Protocol::HTTP1
        else raise "Unsupported protocol: #{remote_version}. Must be either :h2 or :http11 or :http1 or :http10"
        end
      end
    end
  end
end
