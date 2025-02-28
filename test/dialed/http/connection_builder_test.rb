# frozen_string_literal: true

require 'test_helper'

module Dialed
  module HTTP
    class ConnectionBuilderTest < Minitest::Test
      def setup
        # Do nothing
      end

      def teardown
        # Do nothing
      end

      def test_destination
        builder = ConnectionBuilder.new
        dest = builder.destination
        config = builder.build
        dest.for_location('google.com')



      end
    end
  end
end
