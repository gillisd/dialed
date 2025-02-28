# frozen_string_literal: true

module Dialed
  module HTTP
    class ExplicitClient < Client
      def initialize(connection_builder)
        super
        @dialer = Dialer.new(connection_builder, lazy: false)
      end

      protected

      def fetch_dialer(&block)
        block.call(@dialer)
      end
    end
  end
end
