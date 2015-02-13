# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

require_relative '../lib/swim/swim'

describe 'Swim' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @uri = uri
  end

  describe '::Trigger' do

    it 'return true if modified.' do
      cond    = Swim::Cond::Modify("Last Modify - 2015/02/14")
      trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
      actual = Swim.trigger(trigger, @agent)
      expect(actual).to be_falsey
    end

    it 'return true if modified.' do
      cond    = Swim::Cond::Modify("Last Modify - 2015/02/15")
      trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
      actual = Swim.trigger(trigger, @agent)
      expect(actual).to be_truthy
    end
  end

  describe '::ContentNode' do
    before { @node = Swim::ContentNode.new('/html/body/p[1]', "title") }

    it 'scrape content text <p>Hello,Swim</p>' do
      page = @agent.get(@uri)
      actual = @node.inject(@agent, page)
      expect(actual).to eq "Hello,Swim"
    end
  end

  describe '::LinksNode' do
    before { @root_page = @agent.get(@uri) }

    it 'scrape links' do
      root_node = Swim::LinksNode.new('/html/body/a', "root", [
        Swim::ContentNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @root_page)
      expected = [
        {"content" => "Child 01 page."},
        {"content" => "Child 02 page."},
        {"content" => "Child 03 page."},
      ]
      expect(actual).to match expected
    end
  end
end
