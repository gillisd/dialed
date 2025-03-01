# frozen_string_literal: true

require 'test_helper'

module Dialed
  module HTTP
    class ActorExecutorTest < Minitest::Test
      def setup
        @executor = ActorExecutor.new
      end

      def teardown
        @executor.close if @executor&.running?
      end

      def test_get_success
        responses = []
        10.times do |i|
          response = @executor.get("/get", query: { request: i })
          refute_nil response
          responses << response
        end

        assert_equal 10, responses.size
      end

      def test_timeout
        # Assuming there's a slow endpoint available for testing
        assert_raises(ActorExecutor::RequestTimeoutError) do
          @executor.get("/delay/5", timeout: 0.5)
        end
      end

      def test_http_error_code_no_raise
        response = @executor.get("/status/500")
        assert_equal 500, response.status
      end

      def test_error_propagation
        client = ActorExecutor.build_client
        executor = ActorExecutor.new(client)
        client.stub(:get, ->(*args) { raise "Simulated error" }) do
          begin
            executor.get("/ip")
            flunk "Expected an exception but none was raised"
          rescue => e
            assert_equal "Simulated error", e.message
          end
        end
      end

      def test_executor_reuse
        # First batch
        10.times do |i|
          response = @executor.get("/get", query: { request: i })
          refute_nil response
        end

        # Second batch with the same executor
        10.times do |i|
          response = @executor.get("/get", query: { request: i + 10 })
          refute_nil response
        end
      end

      def test_close_and_reopen
        # Use and close first executor
        5.times do |i|
          @executor.get("/get", query: { request: i })
        end
        @executor.close
        refute @executor.running?

        # Create and use a new executor
        @executor = ActorExecutor.new
        5.times do |i|
          response = @executor.get("/get", query: { request: i })
          refute_nil response
        end
      end

      def test_closed_executor_raises_error
        @executor.close
        assert_raises(ActorExecutor::ExecutorClosedError) do
          @executor.get("/get")
        end
      end
    end
  end
end