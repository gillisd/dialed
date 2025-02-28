module Dialed
  module HTTP
    class Request
      attr_reader :verb, :path, :args, :options

      def initialize(verb, path, *args, **options)
        @verb = verb
        @path = path
        @args = args
        @options = options
      end

      def call(connection)
        # protocol_request = Protocol::HTTP::Request[
        #   verb,
        #   path,
        #   *args,
        #   version: connection.version,
        #   headers: options[:headers],
        #   method: verb.upcase,
        #   authority: connection.authority,
        #   scheme:    connection.scheme,
        # ]
        if connection.nil_connection?
          raise Dialed::Error, "Connection is nil"
        end
        protocol_request = Protocol::HTTP::Request.new.tap do |r|
          r.path = path
          r.method = verb.upcase
          r.headers = options[:headers] if options[:headers]
          r.version = connection.version
          r.authority = connection.authority
          r.scheme = connection.scheme
          r.body = options[:body]
          r.protocol = options[:protocol] if options[:protocol]
        end

        protocol_request.call(connection)
      end
    end
  end
end
