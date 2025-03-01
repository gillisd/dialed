# frozen_string_literal: true

require 'test_helper'

module Dialed
  module HTTP
    class ActorExecutorTest < Minitest::Test

      def test_get
        executor = ActorExecutor.new

        10.times do |i|
          puts executor.get("/get", query: { request: i})
        end
        executor.close
        executor2 = ActorExecutor.new

        10.times do |i|
          puts executor2.get("/get", query: { request: i})
        end
        executor2.close
      end
    end
  end
end
