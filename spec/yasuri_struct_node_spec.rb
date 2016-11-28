
# Author::    TAC (tac@tac42.net)

require_relative 'spec_helper'

##########
# Struct #
##########
describe 'Yasuri' do
  include_context 'httpserver'

  describe '::StructNode' do
    before do
      @agent = Mechanize.new
      @page = @agent.get(uri + "/struct/structual_text.html")

      @table_1996 = [
        { "title"    => "The Perfect Insider",
          "pub_date" => "1996/4/5" },
        { "title"    => "Doctors in Isolated Room",
          "pub_date" => "1996/7/5" },
        { "title"    => "Mathematical Goodbye",
          "pub_date" => "1996/9/5" },
      ]
      @table_1997 = [
        { "title"    => "Jack the Poetical Private",
          "pub_date" => "1997/1/5" },
        { "title"    => "Who Inside",
          "pub_date" => "1997/4/5" },
        { "title"    => "Illusion Acts Like Magic",
          "pub_date" => "1997/10/5" },
      ]
      @table_1998 = [
        { "title"    => "Replaceable Summer",
          "pub_date" => "1998/1/7" },
        { "title"    => "Switch Back",
          "pub_date" => "1998/4/5" },
        { "title"    => "Numerical Models",
          "pub_date" => "1998/7/5" },
        { "title"    => "The Perfect Outsider",
          "pub_date" => "1998/10/5" },
      ]
      @all_tables = [
        {"table" => @table_1996},
        {"table" => @table_1997},
        {"table" => @table_1998},
      ]
    end

    it 'scrape single table contents' do
      node = Yasuri::StructNode.new('/html/body/table[1]/tr', "table", [
        Yasuri::TextNode.new('./td[1]', "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expected = @table_1996
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end

    it 'return single result without array' do
      node = Yasuri::StructNode.new('/html/body/table[1]/tr[1]', "table_first_tr", [
        Yasuri::TextNode.new('./td[1]', "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expected = @table_1996.first
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end

    it 'return empty text if no match node' do
      no_match_xpath = '/html/body/table[1]/t'
      node = Yasuri::StructNode.new(no_match_xpath, "table", [
        Yasuri::TextNode.new('./td[1]', "title")
      ])
      actual = node.inject(@agent, @page)
      expect(actual).to be_empty
    end

    it 'fail with invalid xpath' do
      invalid_xpath = '/html/body/table[1]/table[1]/tr['
      node = Yasuri::StructNode.new(invalid_xpath, "table", [
        Yasuri::TextNode.new('./td[1]', "title")
      ])
      expect { node.inject(@agent, @page) }.to raise_error(Nokogiri::XML::XPath::SyntaxError)
    end

    it 'fail with invalid xpath in children' do
      invalid_xpath = './td[1]['
      node = Yasuri::StructNode.new('/html/body/table[1]/tr', "table", [
        Yasuri::TextNode.new(invalid_xpath, "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expect { node.inject(@agent, @page) }.to raise_error(Nokogiri::XML::XPath::SyntaxError)
    end

    it 'scrape all tables' do
      node = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      expected = @all_tables
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end

    it 'can be defined by DSL, scrape all tables' do
      generated = Yasuri.struct_tables '/html/body/table' do
        struct_table './tr' do
          text_title    './td[1]'
          text_pub_date './td[2]'
        end
      end
      original = Yasuri::StructNode.new('/html/body/table', "tables", [
        Yasuri::StructNode.new('./tr', "table", [
          Yasuri::TextNode.new('./td[1]', "title"),
          Yasuri::TextNode.new('./td[2]', "pub_date"),
        ])
      ])
      compare_generated_vs_original(generated, original, @page)
    end

    it 'return child node as symbol' do
      node = Yasuri::StructNode.new('/html/body/table[1]/tr', "table", [
        Yasuri::TextNode.new('./td[1]', "title"),
        Yasuri::TextNode.new('./td[2]', "pub_date"),
      ])
      expected = @table_1996.map{|h| h.map{|k,v| [k.to_sym, v] }.to_h }
      actual = node.inject(@agent, @page, symbolize_names:true)
      expect(actual).to match expected
    end

  end

  describe '::StructNode::Links' do
    before do
      @agent = Mechanize.new
      @page = @agent.get(uri + "/struct/structual_links.html")

      @table = [
        { "title" => "Child01,02",
          "child" => [{"p" => "Child 01 page."}, {"p" => "Child 02 page."}] },

        { "title" => "Child01,02,03",
          "child" => [{"p" => "Child 01 page."}, {"p" => "Child 02 page."}, {"p" => "Child 03 page."}]}
      ]
    end

    it 'return child node in links inside struct' do
      node = Yasuri::StructNode.new('/html/body/table/tr', "table", [
        Yasuri::TextNode.new('./td[1]', "title"),
        Yasuri::LinksNode.new('./td/a', "child", [
          Yasuri::TextNode.new('/html/body/p', "p"),
        ])
      ])
      expected = @table
      actual = node.inject(@agent, @page)
      expect(actual).to match expected
    end
  end # descrive
end
