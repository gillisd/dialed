# frozen_string_literal: true
require 'concurrent'
require 'open-uri'

require 'test_helper'

module Dialed
  module HTTP
    class AsyncProxyTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      class DemoExecutor
        def self.wrap_async
          Concurrent::Future.execute do
            yield
          end
        end
      end

      class Demo
        def get(url)
          response = URI.open(url)
          response.read
        end

        def executor
          DemoExecutor.new
        end
      end

      def test_foo
        proxy = AsyncProxy.new(Demo.new)
        response = proxy.async do |yielder|
          yielder << proxy.get('https://httpbin.org/anything')
          yielder << proxy.get('https://httpbin.org/anything')
          yielder << proxy.get('https://httpbin.org/anything')
        end
        puts response.to_a
      end
    end
  end
end
