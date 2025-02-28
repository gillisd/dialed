# Dialed

A modern, ergonomic HTTP client for Ruby built on top of [async-http](https://github.com/socketry/async-http). Designed to embody the [principle of least surprise](https://en.wikipedia.org/wiki/Principle_of_least_astonishment#:~:text=In%20user%20interface%20design%20and,not%20astonish%20or%20surprise%20users).

Currently in alpha, but supports the following:
* HTTP/2
* HTTP proxying via CONNECT
* Persistent connections
* Concurrent requests
 
And partially supports (still WIP):
* HTTP/1.X
* Automatic connection pooling




##



## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
bundle add dialed
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install dialed
```

## Usage
```ruby
client = Dialed::Client.build do |c|
  c.version = 'HTTP/2'
  c.host = 'httpbin.org'
  c.port = 443
  c.proxy do |p|
    p.host = 'localhost'
    p.port = '8888'
  end
end

# Synchronous usage:
# 
result = client.get('/get')
puts result


# Asynchronous usage:
# 
# Supports all the primitives of the wonderful async gem, and also includes a helper
# for less boilerplate:
#
task = client.async do |async_client, yielder|
  
  10.times do
    yielder << async_client.get('/get')
  end
end

# the task produces an Enumerator::Lazy instance
result_enum = task.wait

result_enum.each do |result|
  puts result
end
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/dialed.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
