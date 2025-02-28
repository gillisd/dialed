# frozen_string_literal: true

require "test_helper"

class TestDialed < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Dialed::VERSION
  end

  def test_it_does_something_useful
    Sync do |t|
      client = Dialed::Client.build do |c|
        c.version = '2.0'
        c.uri = 'https://httpbin.org:443'
        c.proxy = 'http://localhost:8899'
      end
      results =  10.times.map do
        result  = t.async do
          response = client.get('/get?foo=bar', headers: { 'x-foo': 'bar' })
        end
      end.map(&:wait)

      puts results

      client.close

      # response =  client.get('https://httpbin.org/ip')
      # puts response
      #
      # response =  client.get('https://example.com')
      # puts response.read
    end

    # 10.times do
    #   result = client.get('/get')
    #   puts result
    # end
    # client.close
  end
end
