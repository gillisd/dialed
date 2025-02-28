# frozen_string_literal: true

module Dialed
  module HTTP
    class Response
      delegate :to_io, :read, :to_h, :to_s, to: :body

      def initialize(internal_response)
        @internal_response = internal_response
        @notifier = Async::Notification.new
        @internal_response.buffered!
      end

      def body
        @body ||= body_klass.new(internal_response.body)
      end

      def body_klass
        case headers
        in { 'content-type': 'application/json' }
          JsonBody
        else
          EveryBody
        end
      end

      def http2?
        internal_response.version == 'HTTP/2'
      end

      def http11?
        internal_response.version == 'HTTP/1.1'
      end

      def headers
        @headers ||= internal_response
          &.headers
          &.to_h
          &.transform_keys(&:to_sym)
      end

      private

      attr_reader :internal_response
    end
  end
end
