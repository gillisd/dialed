module Dialed
  module HTTP
    class Request
      using Dialed::Refinements::Presence

      attr_reader :verb, :path, :args, :options

      def initialize(verb, path, *args, **options)
        @verb = verb
        @path = path
        @args = args
        @options = options
      end

      def call(connection)
        if connection.nil_connection?
          raise Dialed::Error, "Connection is nil"
        end

        path_uri = Addressable::URI.parse(path)
        path_query = path_uri.query_values || {}

        query = options.fetch(:query, {})
        merged_query = path_query.merge(query)
        path_with_query = path_uri.tap do |u|
          u.query_values = merged_query if merged_query.present?
        end
        header_object = Protocol::HTTP::Headers[options[:headers].transform_keys(&:to_s)]

        protocol_request = Protocol::HTTP::Request.new.tap do |r|
          r.path = path_with_query.to_s
          r.method = verb.upcase
          r.headers = header_object
          r.version = connection.version
          r.authority = connection.authority
          r.scheme = connection.scheme
          r.body = options[:body] if options[:body]
          r.protocol = options[:protocol] if options[:protocol]
        end

        protocol_request.call(connection)
      end
    end
  end
end
