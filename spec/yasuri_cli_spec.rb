require_relative 'spec_helper'

describe 'Yasuri' do
  include_context 'httpserver'
  let(:res_dir) { File.expand_path('cli_resources', __dir__) }

  describe 'cli scrape' do
    it 'require --file or --json option' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], {})
      end.to output("ERROR: Only one of `--file` or `--json` option should be specified.\n").to_stderr
    end

    it 'only one of --file or --json option' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { file: 'path.json', json: '{"text_title": "/html/head/title"}' })
      end.to output("ERROR: Only one of `--file` or `--json` option should be specified.\n").to_stderr
    end

    it 'require --file option is not empty string' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { file: 'file' })
      end.to output("ERROR: --file option require not empty argument.\n").to_stderr
    end

    it 'require --json option is not empty string' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { json: 'json' })
      end.to output("ERROR: --json option require not empty argument.\n").to_stderr
    end

    it 'display text node as simple string' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { json: '{"text_title": "/html/head/title"}' })
      end.to output("Yasuri Test\n").to_stdout
    end

    it 'display texts in single json' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { json: '{"text_c1":"/html/body/p[1]", "text_c2":"/html/body/p[2]"}' })
      end.to output('{"c1":"Hello,Yasuri","c2":"Last Modify - 2015/02/14"}' << "\n").to_stdout
    end

    it 'display text node as simple string via json file' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, ["#{uri}/pagination/page01.html"], { file: "#{res_dir}/tree.json" })
      end.to output(
        '[{"content":"PaginationTest01"},{"content":"PaginationTest02"},' \
        '{"content":"PaginationTest03"},{"content":"PaginationTest04"}]' \
        "\n"
      ).to_stdout
    end

    it 'display text node as simple string via yaml file' do
      expect do
        Yasuri::CLI.new.invoke(:scrape, ["#{uri}/pagination/page01.html"], { file: "#{res_dir}/tree.yml" })
      end.to output(
        '[{"content":"PaginationTest01"},{"content":"PaginationTest02"},' \
        '{"content":"PaginationTest03"},{"content":"PaginationTest04"}]' \
        "\n"
      ).to_stdout
    end

    it 'interval option is effect for each request' do
      allow(Kernel).to receive(:sleep)

      expect do
        Yasuri::CLI.new.invoke(
          :scrape,
          ["#{uri}/pagination/page01.html"],
          { file: "#{res_dir}/tree.yml", interval: 500 }
        )
      end.to output(
        '[{"content":"PaginationTest01"},{"content":"PaginationTest02"},' \
        '{"content":"PaginationTest03"},{"content":"PaginationTest04"}]' \
        "\n"
      ).to_stdout

      expect(Kernel).to have_received(:sleep).exactly(4).times do |interval_sec|
        expect(interval_sec).to match 0.5
      end
    end

    it 'display ERROR when json string is wrong' do
      wrong_json = '{,,}'
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { json: wrong_json })
      end.to output(
        'ERROR: Failed to convert json to yasuri tree. ' \
        "809: unexpected token at '#{wrong_json}'\n"
      ).to_stderr
    end

    it 'display ERROR when json file contains is wrong' do
      file_path = "#{res_dir}/tree_wrong.json"
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { file: file_path })
      end.to output(
        "ERROR: Failed to convert to yasuri tree `#{file_path}`. " \
        "(<unknown>): did not find expected node content while parsing a flow node at line 2 column 3\n"
      ).to_stderr
    end

    it 'display ERROR when yaml file contains is wrong' do
      file_path = "#{res_dir}/tree_wrong.yml"
      expect do
        Yasuri::CLI.new.invoke(:scrape, [uri], { file: file_path })
      end.to output(
        "ERROR: Failed to convert to yasuri tree `#{file_path}`. " \
        "(<unknown>): did not find expected node content while parsing a block node at line 1 column 1\n"
      ).to_stderr
    end
  end
end
