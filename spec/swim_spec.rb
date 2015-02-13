#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

require_relative '../lib/swim/swim'

describe 'ContentNode' do
  include_context 'httpserver'
  before do
    @agent = Mechanize.new
    @uri = uri
  end

  describe '::ContentNode' do
    before { @node = Swim::ContentNode.new('/html/body/p', "title") }

    it 'scrape content text <p>Hello,Swim</p>' do
      page = @agent.get(@uri)
      actual = @node.inject(@agent, page)
      expect(actual).to eq "Hello,Swim"
    end
  end
end
