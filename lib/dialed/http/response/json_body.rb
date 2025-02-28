module Dialed
  module HTTP
    class Response::JsonBody < Response::Body
      alias to_json to_s

      def read
        # already memoized
        buffered_internal_body
      end

      def to_s
        read.to_s
      end

      def to_h
        @__to_h ||= JSON.parse(read, symbolize_names: true)
      end

      def as_json
        @__as_json ||= JSON.parse(read, symbolize_names: false)
      end

      def deconstruct_keys(keys)
        keys ? to_h.slice(*keys) : to_h
      end
    end
  end
end
