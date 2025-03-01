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
          # time = Benchmark.measure do
          reader, writer = IO.pipe
          writer.binmode
          writer.sync = true
          reader.binmode
          reader.sync = true
          # io = StringIO.new(internal_body.read)
          internal_body.call(writer)

          # io.rewind
          # reader = io
          # writer.close
          Zlib::GzipReader.wrap(reader).read
        in :none
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
