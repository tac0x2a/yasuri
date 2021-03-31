require 'thor'
require 'json'
require 'yasuri'

module Yasuri
  class CLI < Thor
    package_name "yasuri"

    default_command :scrape
    desc "scrape <URI> [[--file <TREE_FILE>] or [--json <JSON>]]",
         "Getting from <URI> and scrape it. with <JSON> or json/yml from <TREE_FILE>. They should be Yasuri's format json or yaml string."
    option :file,     {aliases: 'f', desc: "path to file that written yasuri tree as json or yaml", type: :string}
    option :json,     {aliases: 'j', desc: "yasuri tree format json string", type: :string}
    option :interval, {aliases: 'i', desc: "interval each request [ms]", type: :numeric}
    def scrape(uri)
      begin
        test_arguments(options)
      rescue => e
        $stderr.puts e.message
        return -1
      end

      interval_ms = options[:interval] || Yasuri::DefaultInterval_ms
      file_path = options[:file]
      json_string = options[:json]

      begin
        tree = make_tree(file_path, json_string)
        result = tree.scrape(uri, interval_ms: interval_ms)
      rescue => e
        $stderr.puts e.message
        return -1
      end

      if result.instance_of?(String)
        puts result
      else
        j result
      end

      return 0
    end

    private

    def test_arguments(options)
      too_many_options = [options[:file], options[:json]].compact.count != 1
      raise "ERROR: Only one of `--file` or `--json` option should be specified." if too_many_options

      empty_file_argument = options[:file]&.empty? || options[:file] == "file" || options[:json]&.empty?
      raise "ERROR: --file option require not empty argument." if empty_file_argument

      empty_json_string_argument = options[:json]&.empty? || options[:json] == "json"
      raise "ERROR: --json option require not empty argument." if empty_json_string_argument
    end

    def make_tree(file_path, json_string)
      if file_path
        begin
          src = File.read(file_path)
          make_tree_from_file(src)
        rescue => e
          raise "ERROR: Failed to convert to yasuri tree `#{file_path}`. #{e.message}"
        end
      else
        begin
          Yasuri.json2tree(json_string)
        rescue => e
          raise "ERROR: Failed to convert json to yasuri tree. #{e.message}"
        end
      end
    end

    def make_tree_from_file(src)
        Yasuri.json2tree(src) rescue Yasuri.yaml2tree(src)
    end
  end
end