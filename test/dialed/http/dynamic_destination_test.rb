# frozen_string_literal: true

require 'test_helper'

module Dialed
  module HTTP
    class DynamicDestinationTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_foo
        dest = DynamicDestination.new
        result = dest.for_location('google.com')
        puts result
      end
    end
  end
end
