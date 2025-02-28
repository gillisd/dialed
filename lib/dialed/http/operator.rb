# frozen_string_literal: true

module Dialed
  module HTTP
    class Operator
      include Singleton

      def initialize
        @dialers = {}
      end

      def request_call(&block)
        connection_builder = block.call(ConnectionBuilder.new) if block_given?
        connection_builder ||= ConnectionBuilder.apply_defaults
      end

      def singleplex_dialers
        @dialers
          .reject { |_, dialer| dialer.disconnected? }
          .select { |_, dialer| dialer.singleplex? }
      end

      def multiplex_dialers
        @dialers.reject { |_, dialer| dialer.disconnected? }
          .select { |_, dialer| dialer.multiplex? }
      end

      def checkout_dialer(connection_builder, &block)
        full_connection_uri = connection_builder.full_connection_uri
        plex_type = connection_builder.plex_type
        case [full_connection_uri, plex_type, registry.keys]
        in [URI => uri, :h2, [*, ^uri, *]]
          block.call multiplex_dialers.fetch(uri)
        in [URI => uri, :h1 | :h11, [*, ^uri, *]]
          # not thread safe. Use async gem as it is not implemented with threads
          dialer = remove_dialer(uri)
          raise Dialed::Error, 'Dialer not found when it was expected to be. Is it possible you are using multiple threads?' unless dialer

          block.call dialer
          register_dialer dialer
        in [URI => uri, Symbol, Array]
          register_dialer dialer
          block.call dialer
        else
          raise Dialed::Error, "Unknown Dialer type: #{full_connection_uri}, #{plex_type}"
        end
      end

      def fetch_dialer(_uri, &)
        Dialer.new(connection_builder, &)
      end

      def remove_dialer(dialer)
        @dialers.delete(dialer.full_connection_uri)
      end

      def register_dialer(dialer)
        @dialers[dialer.full_connection_uri] = dialer
      end
    end
  end
end
