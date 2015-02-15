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

  describe '::Cond' do
    describe '::NewerThen' do
      it 'return true if content is newer then condition.' do
        cond    = Swim::Cond::NewerThen( Time.parse("2014/02/15") )
        trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
        actual = Swim.trigger(trigger, @agent)
        expect(actual).to be_truthy
      end
      it 'return false if content is newer then condition.' do
        cond    = Swim::Cond::NewerThen( Time.parse("2016/02/15") )
        trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
        actual = Swim.trigger(trigger, @agent)
        expect(actual).to be_falsey
      end
    end

    describe '::OlderThen' do
      it 'return true if content is older then condition.' do
        cond    = Swim::Cond::OlderThen( Time.parse("2014/02/15") )
        trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
        actual = Swim.trigger(trigger, @agent)
        expect(actual).to be_falsey
      end
      it 'return false if content is newer then condition.' do
        cond    = Swim::Cond::OlderThen( Time.parse("2016/02/15") )
        trigger = Swim::Trigger.new(@uri, '/html/body/p[2]', cond)
        actual = Swim.trigger(trigger, @agent)
        expect(actual).to be_truthy
      end
    end
  end # of ::Cond

  describe '::Node' do
    before { @node = Swim::Node.new('//a', 'sample')}
    it 'fail not implemented method' do
      expect{ @node.inject(@agent,@uri) }.to raise_error
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

  describe 'DSL' do
    describe 'content_node' do
      it "return single ContentNode" do
        generated = content_node '/html/body/p[1]', "title"
        original  = Swim::ContentNode.new('/html/body/p[1]', "title")

        page = @agent.get(@uri)
        expected = original.inject(@agent, page)
        actual   = generated.inject(@agent, page)

        expect(actual).to match expected
      end
    end
  end
end
