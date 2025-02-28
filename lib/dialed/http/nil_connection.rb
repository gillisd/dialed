# frozen_string_literal: true

module Dialed
  module HTTP
    class NilConnection < Connection
      NilConnectionError = Class.new(StandardError)
      def initialize(...)
        super(nil, configuration: OpenStruct.new(version: nil, ssl_context: nil))
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

      def create_internal_connection
        raise NilConnectionError, 'Tried to create an internal connection on a NilConnection'
      end

      def internal_connection
        Class.new do
          def call(...)
            raise NilConnectionError, 'Tried to call a nil connection'
          end
        end.new
      end
    end
  end
end
