
# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

########
# Text #
########
describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @index_page = @agent.get(uri)
  end

  describe '::TextNode' do
    before { @node = Yasuri::TextNode.new('/html/body/p[1]', "title") }

    it 'scrape text text <p>Hello,Yasuri</p>' do
      actual = @node.inject(@agent, @index_page)
      expect(actual).to eq "Hello,Yasuri"
    end

    it 'return empty text if no match node' do
      no_match_node = Yasuri::TextNode.new('/html/body/no_match_node', "title")
      actual = no_match_node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end

    it 'fail with invalid xpath' do
      invalid_xpath = '/html/body/no_match_node['
      node = Yasuri::TextNode.new(invalid_xpath, "title")
      expect { node.inject(@agent, @index_page) }.to raise_error
    end

    it "can be defined by DSL, return single TextNode title" do
      generated = Yasuri.text_title '/html/body/p[1]'
      original  = Yasuri::TextNode.new('/html/body/p[1]', "title")
      compare_generated_vs_original(generated, original, @index_page)
    end

    it "can be truncated with regexp" do
      node  = Yasuri.text_title '/html/body/p[1]', /^[^,]+/
      actual = node.inject(@agent, @index_page)
      expect(actual).to eq "Hello"
    end

    it "can be truncated with regexp" do
      node = Yasuri.text_title '/html/body/p[1]', /[^,]+$/
      actual = node.inject(@agent, @index_page)
      expect(actual).to eq "Yasuri"
    end

    it "return empty string if truncated with no match to regexp" do
      node = Yasuri.text_title '/html/body/p[1]', /^hoge/
      actual = node.inject(@agent, @index_page)
      expect(actual).to be_empty
    end
  end
end
