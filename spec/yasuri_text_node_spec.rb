

require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  describe '::TextNode' do
    it 'scrape text text <p>Hello,Yasuri</p>' do
      node = Yasuri::TextNode.new('/html/body/p[1]', "title")
      actual = node.scrape(uri)
      expect(actual).to eq "Hello,Yasuri"
    end

    it 'return empty text if no match node' do
      no_match_node = Yasuri::TextNode.new('/html/body/no_match_node', "title")
      actual = no_match_node.scrape(uri)
      expect(actual).to be_empty
    end

    it 'fail with invalid xpath' do
      invalid_xpath = '/html/body/no_match_node['
      node = Yasuri::TextNode.new(invalid_xpath, "title")
      expect { node.scrape(uri) }.to raise_error(Nokogiri::XML::XPath::SyntaxError)
    end

    it "can be defined by DSL, return single TextNode title" do
      generated = Yasuri.text_title '/html/body/p[1]'
      original = Yasuri::TextNode.new('/html/body/p[1]', "title")
      compare_generated_vs_original(generated, original, uri)
    end

    it "can truncate head by regexp" do
      node = Yasuri.text_title '/html/body/p[1]', truncate: /^[^,]+/
      actual = node.scrape(uri)
      expect(actual).to eq "Hello"
    end

    it "can truncate tail by regexp" do
      node = Yasuri.text_title '/html/body/p[1]', truncate: /[^,]+$/
      actual = node.scrape(uri)
      expect(actual).to eq "Yasuri"
    end

    it "return first captured if matched given capture pattern" do
      node = Yasuri.text_title '/html/body/p[1]', truncate: /H(.+)i/
      actual = node.scrape(uri)
      expect(actual).to eq "ello,Yasur"
    end

    it "return empty string if truncated with no match to regexp" do
      node = Yasuri.text_title '/html/body/p[1]', truncate: /^hoge/
      actual = node.scrape(uri)
      expect(actual).to be_empty
    end

    it "return symbol method applied string" do
      node = Yasuri.text_title '/html/body/p[1]', proc: :upcase
      actual = node.scrape(uri)
      expect(actual).to eq "HELLO,YASURI"
    end

    it "return apply multi arguments" do
      node = Yasuri.text_title '/html/body/p[1]', { proc: :upcase, truncate: /H(.+)i/ }
      actual = node.scrape(uri)
      expect(actual).to eq "ELLO,YASUR"
    end
  end
end
