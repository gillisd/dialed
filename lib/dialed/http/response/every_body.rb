# frozen_string_literal: true

module Dialed
  module HTTP
    class Response::EveryBody < Response::Body
      def read
        buffered_internal_body
      end

      def to_s
        read.to_s
      end
    end
  end
end
