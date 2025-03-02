# frozen_string_literal: true

require_relative 'lib/dialed/version'

Gem::Specification.new do |spec|
  spec.name = 'dialed'
  spec.version = Dialed::VERSION
  spec.authors = [' David Gillis']
  spec.email = ['david@flipmine.com']

  spec.summary = 'A modern, ergonomic HTTP client built on top of async-http'
  spec.description = 'Supports HTTP/2, HTTP/1.X, HTTP proxying, connection pooling, concurrent requests, and lots more'
  spec.homepage = 'https://github.com/gillisd/dialed'
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 2.7.5'

  spec.metadata["allowed_push_host"] = "https://gemsluice.flipmine.com/private"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage

  spec.files = Dir['{lib}/**/*']

  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', '>= 6.1'
  spec.add_dependency 'async', '>= 1.32.1'
  spec.add_dependency 'async-io', '>= 1.43.2'
  spec.add_dependency 'async-http', '>= 0.60.2'
  spec.add_dependency 'addressable', '~> 2.8'
  spec.add_dependency 'zeitwerk'

  spec.add_development_dependency 'minitest', '~> 5.25'
  spec.add_development_dependency 'rake', '>= 13.0'
  spec.add_development_dependency 'irb'


  if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.2.0')
    spec.add_dependency 'backports', '~> 3.25.0'
  end

  spec.metadata['rubygems_mfa_required'] = 'true'
end
