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

      def test_multithreaded_usage
        thread_count = 10
        requests_per_thread = 20
        total_requests = thread_count * requests_per_thread

        # Shared variables for tracking results
        mutex = Mutex.new
        success_count = 0
        failures = []
        execution_times = []

        # Create and start threads
        threads = thread_count.times.map do |thread_id|
          Thread.new do
            thread_results = []
            start_time = Time.now

            requests_per_thread.times do |i|
              begin
                # Each thread makes requests with its own identifier
                response = @executor.get("/get", query: { thread: thread_id, request: i })
                thread_results << response
              rescue => e
                mutex.synchronize do
                  failures << { thread: thread_id, request: i, error: e }
                end
              end
            end

            # Record statistics under lock
            mutex.synchronize do
              success_count += thread_results.size
              execution_times << (Time.now - start_time)
            end
          end
        end

        # Wait for all threads to complete
        threads.each(&:join)

        # Output some statistics
        puts "Multithreaded test completed:"
        puts "- Total successful requests: #{success_count}/#{total_requests}"
        puts "- Average execution time per thread: #{(execution_times.sum / thread_count).round(2)}s"
        puts "- Failures: #{failures.size}"
        failures.each { |f| puts "  - Thread #{f[:thread]}, Request #{f[:request]}: #{f[:error].message}" } if failures.any?

        # Assertions
        assert_equal total_requests, success_count, "All requests should succeed"
        assert_empty failures, "There should be no failures"
      end

      def test_queue_limit
        skip
        small_limit = 5
        executor = ActorExecutor.new(queue_limit: small_limit)

        # Make the client slow so we can hit the queue limit
        client = executor.instance_variable_get(:@client)
        client.define_singleton_method(:original_get) { |*args, **kwargs| client.method(:get).super_method.call(*args, **kwargs) }
        client.define_singleton_method(:get) do |*args, **kwargs|
          sleep(0.5) # Add delay to increase chance of filling queue
          original_get(*args, **kwargs)
        end

        # Start multiple threads to try to fill the queue
        threads = 10.times.map do |i|
          Thread.new do
            begin
              executor.get("/get", query: { request: i }, timeout: 10)
            rescue ActorExecutor::QueueFullError => e
              # Expected for some requests
              e
            rescue => e
              flunk "Unexpected error: #{e.class} - #{e.message}"
            end
          end
        end

        # Collect results
        results = threads.map(&:value)

        # At least some requests should hit the queue limit
        queue_full_count = results.count { |r| r.is_a?(ActorExecutor::QueueFullError) }

        # Cleanup
        executor.close

        assert queue_full_count > 0, "At least some requests should hit the queue limit"

        # Verify the queue size tracking is accurate after all operations
        assert_equal 0, executor.queue_size, "Queue size should be 0 after closing"
      end

      def test_concurrent_close
        # Test that calling close from multiple threads is safe
        executor = ActorExecutor.new

        # Make a few requests first
        5.times { |i| executor.get("/get", query: { request: i }) }

        # Try to close from multiple threads simultaneously
        threads = 5.times.map do
          Thread.new { executor.close }
        end

        # This shouldn't raise any exceptions
        threads.each(&:join)

        refute executor.running?, "Executor should be closed"
      end

      def test_stress_test
        # Skip in regular test runs
        skip "Stress test - run manually"

        # Higher numbers for an actual stress test
        thread_count = 20
        requests_per_thread = 50
        executor = ActorExecutor.new(queue_limit: 500)

        start_time = Time.now
        threads = thread_count.times.map do |thread_id|
          Thread.new do
            requests_per_thread.times do |i|
              begin
                executor.get("/get", query: { thread: thread_id, request: i }, timeout: 30)
              rescue => e
                puts "Error in thread #{thread_id}, request #{i}: #{e.class} - #{e.message}"
              end
            end
          end
        end

        threads.each(&:join)
        total_time = Time.now - start_time

        puts "Stress test completed:"
        puts "- Total requests: #{thread_count * requests_per_thread}"
        puts "- Total time: #{total_time.round(2)}s"
        puts "- Requests per second: #{(thread_count * requests_per_thread / total_time).round(2)}"

        executor.close
      end
    end
  end
end