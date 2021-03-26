
# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

#########
# Links #
#########
describe 'Yasuri' do
  include_context 'httpserver'

  describe '::LinksNode' do
    before do
      @agent = Mechanize.new
      @uri = uri
      @index_page = @agent.get(@uri)
    end

    it 'scrape links' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page)
      expected = [
        {"content" => "Child 01 page."},
        {"content" => "Child 02 page."},
        {"content" => "Child 03 page."},
      ]
      expect(actual).to match expected
    end

    it 'return empty set if no match node' do
      missing_xpath = '/html/body/b'
      root_node = Yasuri::LinksNode.new(missing_xpath, "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end

    it 'scrape links, recursive' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
        Yasuri::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Yasuri::TextNode.new('/html/head/title', "sub_page_title"),
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
    it 'can be defined by DSL, return no contains if no child node' do
      root_node = Yasuri.links_title '/html/body/a'
      actual = root_node.inject(@agent, @index_page)
      expected = [{}, {}, {}] # Empty if no child node under links node.
      expect(actual).to match expected
    end

    it 'can be defined return no contains if no child node' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "title")
      actual = root_node.inject(@agent, @index_page)
      expected = [{}, {}, {}] # Empty if no child node under links node.
      expect(actual).to match expected
    end
    it 'can be defined by DSL, return nested contents under link' do
      generated = Yasuri.links_title '/html/body/a' do
                     text_name '/html/body/p'
                  end
      original = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "name"),
      ])
      compare_generated_vs_original(generated, original, @index_page)
    end

    it 'can be defined by DSL, return recursive links node' do
      generated = Yasuri.links_root '/html/body/a' do
        text_content '/html/body/p'
        links_sub_link '/html/body/ul/li/a' do
          text_sub_page_title '/html/head/title'
        end
      end

      original = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
        Yasuri::LinksNode.new('/html/body/ul/li/a', "sub_link", [
          Yasuri::TextNode.new('/html/head/title', "sub_page_title"),
        ]),
      ])
      compare_generated_vs_original(generated, original, @index_page)
    end

    it 'return child node as symbol' do
      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])

      actual = root_node.inject(@agent, @index_page, symbolize_names: true )
      expected = [
        {:content => "Child 01 page."},
        {:content => "Child 02 page."},
        {:content => "Child 03 page."},
      ]
      expect(actual).to match expected
    end

    it 'scrape with interval for each request' do
      allow(Kernel).to receive(:sleep)

      root_node = Yasuri::LinksNode.new('/html/body/a', "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      actual = root_node.inject(@agent, @index_page, interval_ms: 100)

      expect(actual.size).to match 3
      expect(Kernel).to have_received(:sleep).exactly(3).times do |interval_sec|
        expect(interval_sec).to match 0.1
      end
    end
  end
end
