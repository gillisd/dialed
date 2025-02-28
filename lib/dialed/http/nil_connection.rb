# frozen_string_literal: true

module Dialed
  module HTTP
    class NilConnection < Connection
      def initialize
        super(uri: nil, version: nil, ssl_context: nil)
      end

      def remote_host
        nil
      end

      def remote_uri
        nil
      end

      def ssl_context
        nil
      end

      def http2?
        false
      end

      def http1?
        false
      end

      def open?
        false
      end

      def nil_connection?
        true
      end

      def closed?
        true
      end

      private

      def internal_connection
        Class.new do
          def call(...)
            raise Dialed::Net::HTTP::ConnectionError, 'Tried to call a nil connection'
          end
        end.new
      end
    end
  end
end
