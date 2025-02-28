module Dialed
  module HTTP
    class DynamicDestination
      using Refinements::Presence
      def initialize(scheme: 'https')
        @scheme = scheme
      end

      def extract_location(location)
        uri = Addressable::URI.parse(location)
        uri.port = uri.inferred_port
        if uri.scheme =~ /http/ && uri.host.present? && uri.port.present?
          return uri.to_hash.deep_symbolize_keys
        end
        if (result_1 = Addressable::Template.new('{scheme}{host}{/path}{?query*}')
                         &.extract(location)
                         &.deep_symbolize_keys)
          return result_1
        end
        if (result_2 = Addressable::Template.new('{host}{/path}{?query*}')
                         &.extract(location)
                         &.deep_symbolize_keys
        )
          return result_2
        end

        raise ArgumentError, "Invalid location: #{location.inspect}"
      end

      def uri_for(location)
        # TODO handle port here
        extract_result = extract_location(location)
                           &.deep_symbolize_keys

        uri = Addressable::URI.new
        uri.host = extract_result[:host]
        uri.path = extract_result[:path]
        uri.port = extract_result[:port]
        uri.scheme = extract_result[:scheme] || @scheme
        uri.query_values = extract_result[:query]
        uri.port = uri.default_port
        uri.normalize
      end
    end
  end
end