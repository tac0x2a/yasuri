# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'yasuri/version'

Gem::Specification.new do |spec|
  spec.name          = "yasuri"
  spec.version       = Yasuri::VERSION
  spec.authors       = ["TAC"]
  spec.email         = ["tac@tac42.net"]
  spec.summary       = %q{Yasuri is easy scraping library.}
  spec.description   = %q{Yasuri is an easy web-scraping library for supporting "Mechanize".}
  spec.homepage      = "https://github.com/tac0x2a/yasuri"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.bindir        = "exe"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "fuubar"
  spec.add_development_dependency "glint"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "codeclimate-test-reporter"

  spec.add_dependency "mechanize"
  spec.add_dependency "thor"
end
