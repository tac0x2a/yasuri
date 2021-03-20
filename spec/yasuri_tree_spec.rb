require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @index_page = @agent.get(uri)
  end

  describe '::TreeNode' do
    it "multi scrape in singe page" do
      tree = Yasuri.tree_sample do
        text_title  '/html/head/title'
        text_body_p '/html/body/p[1]'
      end
      actual = tree.inject(@agent, @index_page)

      expected = {
        "title"  => "Yasuri Test",
        "body_p" => "Hello,Yasuri"
      }
      expect(actual).to include expected
    end

    it "nested multi scrape in singe page" do
      tree = Yasuri.tree_sample do
        tree_group1 { text_child01  '/html/body/a[1]' }
        tree_group2 do
          text_child01 '/html/body/a[1]'
          text_child03 '/html/body/a[3]'
        end
      end
      actual = tree.inject(@agent, @index_page)

      expected = {
        "group1" => {
          "child01" => "child01"
        },
        "group2" => {
          "child01" => "child01",
          "child03" => "child03"
        }
      }
      expect(actual).to include expected
    end

    it "scrape with links node" do
      tree = Yasuri.tree_sample do
        tree_group1 do
          links_a '/html/body/a' do
            text_content '/html/body/p'
          end
          text_child01  '/html/body/a[1]'
        end
        tree_group2 do
          text_child03 '/html/body/a[3]'
        end
      end
      actual = tree.inject(@agent, @index_page)

      expected = {
        "group1" => {
          "a" => [
            {"content" => "Child 01 page."},
            {"content" => "Child 02 page."},
            {"content" => "Child 03 page."},
          ],
          "child01" => "child01"
        },
        "group2" => { "child03" => "child03" }
      }
      expect(actual).to include expected
    end
  end
end