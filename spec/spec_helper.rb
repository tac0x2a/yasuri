# -*- coding: utf-8 -*-
# Author::    TAC (tac@tac42.net)

require 'glint'
Dir[File.expand_path("../servers/*.rb", __FILE__)].each {|f| require f}

require 'rspec'
shared_context 'httpserver' do
  require 'net/http'
  let(:uri) {
    "http://#{Glint::Server.info[:httpserver][:host]}:#{Glint::Server.info[:httpserver][:port]}"
  }
end

require 'simplecov'
require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start


$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'yasuri'

def compare_generated_vs_original(generated, original, page)
  expected = original.inject(@agent, page)
  actual   = generated.inject(@agent, page)
  expect(actual).to match expected
end
