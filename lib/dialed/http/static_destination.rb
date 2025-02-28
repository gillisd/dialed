module Dialed
  module HTTP
    class StaticDestination
      def initialize(uri)
        @uri = uri
      end

      def uri_for(location)
        location_uri = Addressable::URI.parse(location)
        verify_location_is_path!(location_uri)
        @uri.join(location_uri)
      end

      private

      def verify_location_is_path!(location_uri)
        raise Dialed::Error, "Expected location to be a path, but got: #{location_uri.inspect}" unless location_uri.relative?
      end
    end
  end
end