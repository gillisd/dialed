# frozen_string_literal: true

module Dialed
  module HTTP
    class DirectConnection < Connection
      def close
        internal_connection.close
      end

      protected

      def create_internal_connection
        remote_endpoint = Async::HTTP::Endpoint.parse(
          remote_uri.to_s,
          protocol:       async_http_protocol,
          ssl_context:    ssl_context,
          alpn_protocols: ssl_context.alpn_protocols
        )

        remote_sock = remote_endpoint.connect
        async_http_protocol.client(remote_sock)
      end
    end
  end
end
