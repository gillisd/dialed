# frozen_string_literal: true

module Dialed
  module HTTP
    class TunneledConnection < Connection
      ProxyConnectError = Class.new(StandardError)

      delegate :proxy_uri, to: :configuration

      def close
        internal_connection.close
      end

      protected

      def create_internal_connection
        proxy_connection = create_proxy_connection
        remote_endpoint = Async::HTTP::Endpoint.parse(
          remote_uri.to_s,
          protocol:       async_http_protocol,
          ssl_context:    ssl_context,
          alpn_protocols: ssl_context.alpn_protocols
        )

        proxy = Async::HTTP::Proxy.new(proxy_connection, address)
        proxied_endpoint = proxy.wrap_endpoint(remote_endpoint)

        proxied_sock = (
          begin
            proxied_endpoint.connect
          rescue Errno::ECONNRESET => e
            proxy_connection.close
            raise ProxyConnectError, e
          end
        )
        async_http_protocol.client(proxied_sock)
      end

      private

      def create_proxy_connection
        proxy_endpoint = Async::HTTP::Endpoint.parse(proxy_uri.to_s)
        Async::HTTP::Client.new(proxy_endpoint)
      end
    end
  end
end
