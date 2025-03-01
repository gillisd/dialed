# frozen_string_literal: true

require 'bundler/setup'
require 'bootsnap/setup'
require 'backports/3.2.0/data'
require 'zeitwerk'

autoload :Timeout, 'timeout'
autoload :Pathname, 'pathname'
autoload :Async, 'async'
autoload :Tempfile, 'tempfile'
autoload :Open3, 'open3'
autoload :OpenSSL, 'openssl'
autoload :Benchmark, 'benchmark'
autoload :Base64, 'base64'
autoload :SimpleDelegator, 'delegate'
autoload :OpenStruct, 'ostruct'
autoload :Singleton, 'singleton'

require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/hash/keys'

module Kernel
  module_function

  def with_warnings(flag)
    old_verbose, $VERBOSE = $VERBOSE, flag
    yield
  ensure
    $VERBOSE = old_verbose
  end

end

module Addressable
  autoload :URI, 'addressable/uri'
  autoload :Template, 'addressable/template'
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
