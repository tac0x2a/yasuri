
# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

############
# Paginate #
############
describe 'Yasuri' do
  include_context 'httpserver'

  describe '::PaginateNode' do
    before do
      @agent = Mechanize.new
      @uri = uri + "/pagination/page01.html"
      @page = @agent.get(@uri)
    end

    it "scrape each paginated pages" do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
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

    it "scrape each paginated pages limited" do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ], limit:3)
      actual = root_node.inject(@agent, @page)
      expected = [
        {"content" => "PaginationTest01"},
        {"content" => "PaginationTest02"},
        {"content" => "PaginationTest03"},
      ]
      expect(actual).to match expected
    end

    it 'return first content if paginate link node is not found' do
      missing_xpath = "/html/body/nav/span/b[@class='next']"
      root_node = Yasuri::PaginateNode.new(missing_xpath, "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      actual = root_node.inject(@agent, @page)
      expected = [ {"content" => "PaginationTest01"}, ]
      expect(actual).to match_array expected
    end

    it 'return empty hashes if content node is not found' do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/hoge', "content"),
      ])
      actual = root_node.inject(@agent, @page)
      expected = [ {"content" => ""}, {"content" => ""}, {"content" => ""}, {"content" => ""},]
      expect(actual).to match_array expected
    end

    it 'can be defined by DSL, return single PaginateNode content' do
      generated = Yasuri.pages_next "/html/body/nav/span/a[@class='next']" do
        text_content '/html/body/p'
      end
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      compare_generated_vs_original(generated, original, @page)
    end

    it 'can be defined by DSL, return single PaginateNode content limited' do
      generated = Yasuri.pages_next "/html/body/nav/span/a[@class='next']", 2 do
        text_content '/html/body/p'
      end
      original = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ], limit: 2)
      compare_generated_vs_original(generated, original, @page)
    end

    it "return child node as symbol" do
      root_node = Yasuri::PaginateNode.new("/html/body/nav/span/a[@class='next']", "root", [
        Yasuri::TextNode.new('/html/body/p', "content"),
      ])
      actual = root_node.inject(@agent, @page, symbolize_names:true)
      expected = [
        {:content => "PaginationTest01"},
        {:content => "PaginationTest02"},
        {:content => "PaginationTest03"},
        {:content => "PaginationTest04"},
      ]
      expect(actual).to match expected
    end
  end
end
