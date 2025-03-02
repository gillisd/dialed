# frozen_string_literal: true

require 'test_helper'
require 'concurrent'
module Dialed
  module HTTP
    class ClientTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_event_loop
        Sync do
          client = Client.new
          response = client.get('https://httpbin.org/anything')
          puts response
        end
      end

      def test_actor
        client = Client.new
        response = client.get('https://httpbin.org/anything')
        puts response
      end

      def test_async_helper_actor
        client = Client.new
        response = client.async do |yielder|
          10.times do |i|
            yielder << client.get("https://httpbin.org/anything?r=#{i}")
          end
        end

        puts response.to_a
      end

      def test_async_helper_async
        response = nil
        Sync do
          client = Client.new
          response = client.async do |yielder|
            10.times do |i|
              yielder << client.get("https://httpbin.org/anything?r=#{i}")
            end
          end
        end
        puts response.to_a
      end

      def test_parallel_actor

        client = Client.new
        responses = []

        1.times do |i|
          future = Concurrent::Future.execute do
            client.get("https://httpbin.org/get?foo=bar#{i}")
          end
          responses << future
        end
        enum = Enumerator::Lazy.new(responses) do |y, future|
          future.wait
          y << future.value!
        end
        puts enum.next
      end
    end
  end
end
