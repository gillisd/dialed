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
  spec.required_ruby_version = '>= 3.3.0'

  #  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  #  spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  #  gemspec = File.basename(__FILE__)
  spec.files = Dir['{lib}/**/*']
  #  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
  #    ls.readlines("\x0", chomp: true).reject do |f|
  #      (f == gemspec) ||
  #        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
  #    end
  #  end
  #  spec.bindir = 'exe'
  #  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency 'activesupport'
  spec.add_dependency 'addressable'
  spec.add_dependency 'async-http'
  spec.add_dependency 'bundler'
  spec.add_dependency 'zeitwerk'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  #  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.metadata['rubygems_mfa_required'] = 'true'
end
