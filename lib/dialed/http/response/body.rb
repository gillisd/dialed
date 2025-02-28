# frozen_string_literal: true

module Dialed
  module HTTP
    class Response::Body
      def initialize(internal_body)
        @internal_body = internal_body
        @file = nil
      end

      def read
        raise NotImplementedError
      end

      def to_io
        @to_io ||= begin
                     file = nil
                     begin
                       file = ::Tempfile.create(anonymous: true)
                       internal_body.each do |chunk|
                         file.write(chunk)
                       end
                       file.rewind
                       file
                     rescue => e
                       file.close
                       raise e
                     end
                   end
      end

      def http2?; end

      private

      def buffered_internal_body
        @buffered_internal_body ||= begin
                                      if @file
                                        return to_io.tap(&:rewind)
                                                    .read
                                      end
                                      internal_body.read
                                    end
      end

      def internal_body
        if @internal_body.respond_to?(:rewindable?) && @internal_body.rewindable?
          @internal_body
            .rewind
          # elsif @internal_body.is_a?(Async::HTTP::Protocol::HTTP2::Input)
        elsif @internal_body.is_a?(Protocol::HTTP::Body::Buffered)
          @internal_body.rewind
          # buffered_body = @internal_body.finish
          # buffered_body.rewind
        end
        @internal_body
      end
    end
  end
end
