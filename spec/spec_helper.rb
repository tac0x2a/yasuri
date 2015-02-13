#!/usr/bin/env ruby
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
require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'simplecov'
require 'coveralls'
Coveralls.wear!

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]
SimpleCov.start
