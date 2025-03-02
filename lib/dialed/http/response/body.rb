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

      def with_pipe(reader, writer)
        reader, writer = IO.pipe

        begin
          writer.binmode
          reader.binmode
          writer.sync = true

          yield reader, writer
        ensure
          reader.close unless reader.closed?
          writer.close unless writer.closed?
        end
      end

      def buffer_internal_body
        return to_io.tap(&:rewind).read if @file

        case @compression_algorithm
          #TODO need to not call buffered! on response for Gzipreader and other stream readers to increase performance
        when 'gzip'
          with_pipe do |reader, writer|
            internal_body.call(writer)
            writer.close # Close writer to avoid blocking in the read
            Zlib::GzipReader.wrap(reader).read
          end
        when :none
          # Assuming internal_body is IO-like here
          internal_body.read
        else
          raise NotImplementedError, "Compression algorithm '#{@compression_algorithm}' not supported"
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
