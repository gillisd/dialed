module Dialed
  module HTTP
    class ActorExecutor
      def initialize
        @queue = Thread::Queue.new
        @results = {}
        @results_mutex = Mutex.new
        @client = Dialed::Client.build do |c|
          c.version = '2.0'
          c.host = 'httpbin.org'
          c.scheme = 'https'
          c.port = 443
          c.proxy do |p|
            p.host = 'localhost'
            p.port = 8899
          end
        end

        @thread = Thread.new do
          Async do |t|
            main_loop_task = t.async do |g|
              while (payload = @queue.pop)
                result_queue, obj = payload
                response = @client.get(*obj)
                result_queue.push response
              end

              t.stop
              @client.close
            end
            main_loop_task.wait
          end
        end
      end

      def close
        @queue << nil
        @thread.join
      end

      def get(*args, **kwargs)
        result_queue = Queue.new
        @queue << [result_queue, [*args, **kwargs]]
        result_queue.pop
      end
    end
  end
end
