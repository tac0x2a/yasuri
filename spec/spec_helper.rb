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


# ENV['CODECLIMATE_REPO_TOKEN'] = "0dc78d33107a7f11f257c0218ac1a37e0073005bb9734f2fd61d0f7e803fc151"
# require "codeclimate-test-reporter"
# CodeClimate::TestReporter.start

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
