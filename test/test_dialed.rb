# frozen_string_literal: true

require "test_helper"

class TestDialed < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Dialed::VERSION
  end

  def test_it_does_something_useful
    Sync do
      client = Dialed::Client.build do |c|
        c.version = '2.0'
        c.uri = 'https://httpbin.org:443'
        # c.proxy = 'http://localhost:8899'
      end

      10.times do
        result = client.get('/get')
        puts result
      end
      client.close
    end
  end
end
