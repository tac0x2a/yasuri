
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yasuri/version'

Gem::Specification.new do |spec|
  spec.name                  = 'yasuri'
  spec.version               = Yasuri::VERSION
  spec.authors               = ['TAC']
  spec.email                 = ['tac@tac42.net']
  spec.summary               = %q{Yasuri (鑢) is a library for declarative web scraping and cli.}
  spec.description           = %q{Yasuri (鑢) is a library for declarative web scraping and a command line tool for scraping with it.}
  spec.homepage              = 'https://github.com/tac0x2a/yasuri'
  spec.license               = 'MIT'

  spec.files                 = `git ls-files -z`.split("\x0")
  spec.executables           = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.bindir                = 'exe'
  spec.test_files            = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 2.7.0'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'codeclimate-test-reporter'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'glint'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'rubocop-rubycw'
  spec.add_development_dependency 'simplecov'

  spec.add_dependency 'mechanize'
  spec.add_dependency 'thor'
end
