# frozen_string_literal: true

module Dialed
  module HTTP
    class Response::Body
      def initialize(internal_body, compression_algorithm: :none)
        @internal_body = internal_body
        @file = nil
        @compression_algorithm = compression_algorithm
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

      def buffered_internal_body
        @buffered_internal_body ||= buffer_internal_body
      end

      def buffer_internal_body
        if @file
          return to_io.tap(&:rewind)
                      .read
        end
        case @compression_algorithm
        in 'gzip'
          reader, writer = IO.pipe
          writer.binmode
          reader.binmode
          writer.sync = true
          reader.sync = true
          internal_body.call(writer)

          Zlib::GzipReader.wrap(reader).read
        in :none
          internal_body.read
        else
          raise NotImplementedError
        end
      end

      def internal_body
        if @internal_body.respond_to?(:rewindable?) && @internal_body.rewindable?
          @internal_body
            .rewind
        elsif @internal_body.is_a?(Protocol::HTTP::Body::Buffered)
          @internal_body.rewind
        end
        @internal_body
      end
    end
  end
end
