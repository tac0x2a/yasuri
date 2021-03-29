require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  describe '::MapNode' do
    it "multi scrape in singe page" do
      map = Yasuri.map_sample do
        text_title  '/html/head/title'
        text_body_p '/html/body/p[1]'
      end
      actual = map.scrape(uri)

      expected = {
        "title" => "Yasuri Test",
        "body_p" => "Hello,Yasuri"
      }
      expect(actual).to include expected
    end

    it "nested multi scrape in singe page" do
      map = Yasuri.map_sample do
        map_group1 { text_child01 '/html/body/a[1]' }
        map_group2 do
          text_child01 '/html/body/a[1]'
          text_child03 '/html/body/a[3]'
        end
      end
      actual = map.scrape(uri)

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
      map = Yasuri.map_sample do
        map_group1 do
          links_a '/html/body/a' do
            text_content '/html/body/p'
          end
          text_child01 '/html/body/a[1]'
        end
        map_group2 do
          text_child03 '/html/body/a[3]'
        end
      end
      actual = map.scrape(uri)

      expected = {
        "group1" => {
          "a" => [
            { "content" => "Child 01 page." },
            { "content" => "Child 02 page." },
            { "content" => "Child 03 page." }
          ],
          "child01" => "child01"
        },
        "group2" => { "child03" => "child03" }
      }
      expect(actual).to include expected
    end
  end
end
