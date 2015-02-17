# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

require_relative '../lib/swim/swim'

describe 'Swim' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @uri = uri
    @index_page = @agent.get(@uri)
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
      actual = @node.inject(@agent, @index_page)
      expect(actual).to eq "Hello,Swim"
    end
  end

  describe '::LinksNode' do
    it 'scrape links' do
      root_node = Swim::LinksNode.new('/html/body/a', "root", [
        Swim::ContentNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page)
      expected = [
        {"content" => "Child 01 page."},
        {"content" => "Child 02 page."},
        {"content" => "Child 03 page."},
      ]
      expect(actual).to match expected
    end

    it 'scrape links, recursive' do
      root_node = Swim::LinksNode.new('/html/body/a', "root", [
        Swim::ContentNode.new('/html/body/p', "content"),
        Swim::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Swim::ContentNode.new('/html/head/title', "sub_page_title"),
        ]),
      ])
      actual = root_node.inject(@agent, @index_page)
      expected = [
        {"content"  => "Child 01 page.",
         "sub_link" => [{"sub_page_title" => "Child 01 SubPage Test"},
                        {"sub_page_title" => "Child 02 SubPage Test"}],},
        {"content" => "Child 02 page.",
         "sub_link" => [],},
        {"content" => "Child 03 page.",
         "sub_link" => [{"sub_page_title" => "Child 03 SubPage Test"}],},
      ]
      expect(actual).to match expected
    end

    describe '::PaginateNode' do
      before do
        @uri += "/pagination/page01.html"
        @page = @agent.get(@uri)
      end

      it "scrape each paginated pages" do
        root_node = Swim::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
          Swim::ContentNode.new('/html/body/p', "content"),
        ])
        actual = root_node.inject(@agent, @page)
        expected = [
          {"content" => "PaginationTest01"},
          {"content" => "PaginationTest02"},
          {"content" => "PaginationTest03"},
          {"content" => "PaginationTest04"},
        ]
        expect(actual).to match expected
      end
    end
  end

  describe 'DSL' do

    def compare_generated_vs_original(generated, original, page = @index_page)
      expected = original.inject(@agent, page)
      actual   = generated.inject(@agent, page)
      expect(actual).to match expected
    end

    it "return single ContentNode title" do
      generated = text_title '/html/body/p[1]'
      original  = Swim::ContentNode.new('/html/body/p[1]', "title")
      compare_generated_vs_original(generated, original)
    end

    it 'return single LinkNode title' do
      generated = links_title     '/html/body/a'
      original  = Swim::LinksNode.new('/html/body/a', "title")
      compare_generated_vs_original(generated, original)
    end
    it 'return nested contents under link' do
      generated = links_title '/html/body/a' do
                     text_name '/html/body/p'
                  end
      original = Swim::LinksNode.new('/html/body/a', "root", [
        Swim::ContentNode.new('/html/body/p', "name"),
      ])
      compare_generated_vs_original(generated, original)
    end

    it 'return recursive links node' do
      generated = links_root '/html/body/a' do
        text_content '/html/body/p'
        links_sub_link '/html/body/ul/li/a' do
          text_sub_page_title '/html/head/title'
        end
      end

      original = Swim::LinksNode.new('/html/body/a', "root", [
        Swim::ContentNode.new('/html/body/p', "content"),
        Swim::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Swim::ContentNode.new('/html/head/title', "sub_page_title"),
        ]),
      ])
      compare_generated_vs_original(generated, original)
    end

    it 'return single PaginateNode content' do
      generated = pages_next "/html/body/nav/span/a[@class='next']" do
        text_content '/html/body/p'
      end
      original = Swim::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Swim::ContentNode.new('/html/body/p', "content"),
      ])
      uri = @uri + "/pagination/page01.html"
      page = @agent.get(uri)
      compare_generated_vs_original(generated, original, page)
    end
  end
end
