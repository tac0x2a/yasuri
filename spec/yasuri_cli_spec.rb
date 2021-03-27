require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'

  before do
    @agent = Mechanize.new
    @index_page = @agent.get(uri)

    @res_dir = File.expand_path('../cli_resources', __FILE__)
  end

  describe 'cli scrape' do
    it "require --file or --json option" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {})
      }.to output("ERROR: Only one of `--file` or `--json` option should be specified.\n").to_stderr
    end

    it "only one of --file or --json option" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {file: "path.json", json: '{"text_title": "/html/head/title"}'})
      }.to output("ERROR: Only one of `--file` or `--json` option should be specified.\n").to_stderr
    end

    it "require --file option is not empty string" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {file: "file"})
      }.to output("ERROR: --file option require not empty argument.\n").to_stderr
    end

    it "require --json option is not empty string" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {json: "json"})
      }.to output("ERROR: --json option require not empty argument.\n").to_stderr
    end


    it "display text node as simple string" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {json: '{"text_title": "/html/head/title"}'})
      }.to output("Yasuri Test\n").to_stdout
    end

    it "display texts in single json" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {json: '{"text_c1":"/html/body/p[1]", "text_c2":"/html/body/p[2]"}'})
      }.to output('{"c1":"Hello,Yasuri","c2":"Last Modify - 2015/02/14"}'+"\n").to_stdout
    end


    it "display text node as simple string via json file" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri+"/pagination/page01.html"], {file: "#{@res_dir}/tree.json"})
      }.to output('[{"content":"PaginationTest01"},{"content":"PaginationTest02"},{"content":"PaginationTest03"},{"content":"PaginationTest04"}]' + "\n").to_stdout
    end
    it "display text node as simple string via yaml file" do
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri+"/pagination/page01.html"], {file: "#{@res_dir}/tree.yml"})
      }.to output('[{"content":"PaginationTest01"},{"content":"PaginationTest02"},{"content":"PaginationTest03"},{"content":"PaginationTest04"}]' + "\n").to_stdout
    end

    it "interval option is effect for each request" do
      allow(Kernel).to receive(:sleep)

      Yasuri::CLI.new.invoke(
        :scrape,
        [uri+"/pagination/page01.html"],
        {file: "#{@res_dir}/tree.yml", interval: 500}
      )

      expect(Kernel).to have_received(:sleep).exactly(4).times do |interval_sec|
        expect(interval_sec).to match 0.5
      end
    end

    it "display ERROR when json string is wrong" do
      wrong_json = '{,,}'
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {json: wrong_json})
      }.to output("ERROR: Failed to convert json to yasuri tree. 809: unexpected token at '#{wrong_json}'\n").to_stderr
    end
    it "display ERROR when json file contains is wrong" do
      file_path = "#{@res_dir}/tree_wrong.json"
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {file: file_path})
      }.to output("ERROR: Failed to convert to yasuri tree `#{file_path}`. (<unknown>): did not find expected node content while parsing a flow node at line 2 column 3\n").to_stderr
    end
    it "display ERROR when yaml file contains is wrong" do
      file_path = "#{@res_dir}/tree_wrong.yml"
      expect {
        Yasuri::CLI.new.invoke(:scrape, [uri], {file: file_path})
      }.to output("ERROR: Failed to convert to yasuri tree `#{file_path}`. (<unknown>): did not find expected node content while parsing a block node at line 1 column 1\n").to_stderr
    end
  end
end