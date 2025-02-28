# frozen_string_literal: true

require 'bundler/setup'
require 'backports/3.2.0/data'
require 'zeitwerk'


autoload :Pathname, 'pathname'
autoload :Async, 'async'
autoload :Tempfile, 'tempfile'
autoload :Open3, 'open3'
autoload :OpenSSL, 'openssl'
autoload :Benchmark, 'benchmark'
autoload :Base64, 'base64'
autoload :SimpleDelegator, 'delegate'

require 'active_support/core_ext/module/delegation'

module Addressable
  autoload :URI, 'addressable/uri'
end

module Async
  autoload :Barrier, 'async/barrier'
  autoload :Semaphore, 'async/semaphore'
  autoload :HTTP, 'async/http'
  autoload :Waiter, 'async/waiter'

  module HTTP
    autoload :Client, 'async/http/client.rb'
    autoload :Proxy, 'async/http/proxy.rb'
    autoload :Endpoint, 'async/http/endpoint.rb'
  end
end

loader = Zeitwerk::Loader.for_gem
loader.inflector.inflect(
  'io' => 'IO',
  'http' => 'HTTP'
)
loader.ignore('test/**/*')
loader.ignore('bin/**/*')
loader.setup

module Dialed
  class Error < StandardError; end

  Client = HTTP::Client
end
