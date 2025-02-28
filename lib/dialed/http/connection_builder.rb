# frozen_string_literal: true

module Dialed
  module HTTP
    class ConnectionBuilder
      DirectConnectionConfiguration = Data.define(:uri, :version, :ssl_context)
      TunneledConnectionConfiguration = Data.define(:uri, :proxy_uri, :version, :ssl_context)
      using Dialed::Refinements::Presence

      attr_accessor :ssl_context
      attr_reader :version, :scheme, :uri, :proxy_uri

      delegate :host, :port, :scheme, to: :uri
      delegate :host=, :port=, to: :uri

      def self.apply_defaults
        new.tap(&:apply_defaults!)
      end

      def initialize
        @version = :h2
        @proxy_uri = nil
        @ssl_context = build_ssl_context
        @uri = Addressable::URI.new
        @uri_defaults = { scheme: 'https', port: 443 }
      end

      def build_ssl_context
        OpenSSL::SSL::SSLContext.new.tap do |ssl_context|
          ssl_context.alpn_protocols = %w[h2 http/1.1]
          ssl_context.verify_hostname = true
        end
      end

      def scheme=(scheme)
        uri.scheme = scheme
        case scheme
        in 'http'
          uri.port = 80
        in 'https'
          uri.port = 443
        else
          raise ArgumentError, "Unsupported scheme: #{scheme.inspect}"
        end
      end

      def uri_valid?
        uri.send(:validate).nil?
      end

      def valid?
        uri_valid? && !ssl_context.nil? && version.present?
      end

      def build
        apply_defaults!
        raise Dialed::Error, 'Cannot build. Invalid' unless valid?

        if proxy_uri
          configuration = TunneledConnectionConfiguration.new(
            uri:         uri,
            version:     version,
            ssl_context: ssl_context,
            proxy_uri:   proxy_uri
          )
          TunneledConnection.new(configuration)
        else
          configuration = DirectConnectionConfiguration.new(
            uri:         uri,
            version:     version,
            ssl_context: ssl_context
          )
          DirectConnection.new(configuration)
        end
      end

      def cert_store
        ssl_context.cert_store ||= OpenSSL::X509::Store.new
      end

      def alpn_protocols=(protocols)
        ssl_context.alpn_protocols = protocols
      end

      def alpn_protocols
        ssl_context.alpn_protocols
      end

      def cert_store=(cert_store)
        ssl_context.cert_store = cert_store
      end

      def add_certificate(path)
        pathname = Pathname(path)
        pathname = Pathname(File.expand_path(path)) if pathname.relative?

        certificate = OpenSSL::X509::Certificate.new(pathname.read)
        cert_store.add_cert(certificate)
        self
      end

      def version=(version)
        version = version.to_s

        case version
        in '1.0' | '10' | 1 | 'http/1.0' | 'HTTP/1.0'
          @version = :http10
          self.alpn_protocols = ['http/1.0']
        in '1.1' | '11' | 'http/1.1' | 'HTTP/1.1'
          @version = :http11
          self.alpn_protocols = ['http/1.1']
        in '2.0' | '20' | 2 | 'http/2' | 'HTTP/2'
          @version = :h2
          self.alpn_protocols = ['h2']
        else
          raise ArgumentError, "Unsupported HTTP version: #{version.inspect}"
        end
      end

      def verify_peer=(verify_peer)
        ssl_context.verify_mode = (OpenSSL::SSL::VERIFY_PEER if verify_peer)
      end

      def verify_none=(verify_none)
        ssl_context.verify_mode = (OpenSSL::SSL::VERIFY_NONE if verify_none)
      end

      alias insecure= verify_none=

      def uri=(uri)
        input = Addressable::URI.parse(uri)
        input_no_path = input.dup
        input_no_path.path = nil
        input_no_path.query = nil
        input_no_path.fragment = nil
        @uri = input_no_path
      end

      def proxy(&)
        if block_given?
          uri = ProxyUri.new.tap(&)
          uri.infer_scheme_if_missing!
          raise ArgumentError, "Invalid proxy URI: #{uri.inspect}" unless uri.valid?

          @proxy_uri = uri

          self
        else
          @proxy_uri
        end
        self
      end

      def proxy=(proxy_uri)
        parsed = Addressable::URI.parse(proxy_uri)
        proxy do |self_proxy|
          self_proxy.merge!(parsed)
        end
      end

      alias proxy_uri= proxy=

      def apply_defaults!
        defaults_to_apply = @uri_defaults.select do |key, _value|
          uri_value = uri.send(key)
          next if uri_value.present?

          true
        end

        uri.merge!(defaults_to_apply)
        self
      end
    end
  end
end
