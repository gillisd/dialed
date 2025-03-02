module Dialed
  module HTTP
    class Operator
      include Singleton

      class SemDelegate < SimpleDelegator
        delegate :acquire, to: :semaphore

        def initialize(dialer = nil)
          super
          @semaphore = Async::Semaphore.new
          @semaphore.limit = 0
        end

        def dialer=(dialer)
          __setobj__(dialer)
        end

        def unlock(limit = 100)
          @semaphore.limit = limit
        end

        def call(...)
          @semaphore.acquire do
            if __getobj__.nil?
              raise Dialed::Error, "Dialer is nil"
            end
            __getobj__.call(...)
          end
        end
      end

      def initialize
        @map = {}
      end

      def close
        @map.each_value(&:hangup!)
      end

      def get_dialer(uri, connection_configuration:)
        # TODO handle protocols
        dialer = _get_dialer(uri)
        return dialer if dialer

        delegate = SemDelegate.new
        set_dialer(uri, delegate)
        build_dialer(uri, connection_configuration, delegate)
      end

      def set_dialer(uri, dialer)
        uri_no_path = uri.dup
        uri_no_path.path = nil
        @map[uri_no_path] = dialer
      end

      def _get_dialer(uri)
        uri_no_path = uri.dup
        uri_no_path.path = nil
        @map[uri_no_path]
      end

      def build_dialer(uri, connection_config, delegate)
        uri_no_path = uri.dup
        uri_no_path.path = nil

        dialer = Dialer.new(uri_no_path, configuration: connection_config)
        delegate.dialer = dialer
        dialer.connect
        if dialer.http1?
          delegate.unlock(1)
        else
          delegate.unlock
        end
        dialer
      end

      def validate_no_path_in_uri(uri)
        unless uri.path.nil?
          raise Dialed::Error, "Invalid URI: #{uri}. Path is not allowed for creating new connections."
        end
      end
    end
  end
end
