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
        protocol_request = Protocol::HTTP::Request[
          verb,
          path,
          *args,
          authority: connection.authority,
          scheme:    connection.scheme,
        ]

        protocol_request.call(connection)
      end
    end
  end
end
