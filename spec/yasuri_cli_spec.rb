require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @index_page = @agent.get(uri)
  end

  describe 'cli scrape' do
    it "display text node as simple string" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri, '{"text_title": "/html/head/title"}'])
      }.to output("Yasuri Test\n").to_stdout
    end

    it "display texts in single json" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri, '{"text_c1":"/html/body/p[1]", "text_c2":"/html/body/p[2]"}'])
      }.to output('{"c1":"Hello,Yasuri","c2":"Last Modify - 2015/02/14"}'+"\n").to_stdout
    end
  end
end