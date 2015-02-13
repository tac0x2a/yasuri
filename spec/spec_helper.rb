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
