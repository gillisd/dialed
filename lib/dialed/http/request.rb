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

        query = options.fetch(:query, nil).then { _1.presence }
        path_with_query = Addressable::URI.parse(path).tap do |u|
          u.query_values = query
        end

        protocol_request = Protocol::HTTP::Request.new.tap do |r|
          r.path = path_with_query
          r.method = verb.upcase
          r.headers = options[:headers] if options[:headers]
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
