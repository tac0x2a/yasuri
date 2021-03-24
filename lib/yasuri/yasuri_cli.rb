require 'thor'
require 'json'
require 'yasuri'
require 'mechanize'

module Yasuri
  class CLI < Thor
    desc "scrape <URI> [[--file <TREE_FILE>] or [--json <JSON>]]", "Getting from <URI> and scrape it. with <JSON> or json/yml from <TREE_FILE>. They should be Yasuri's format json or yaml string."
    option :file
    option :json
    def scrape(uri)
      # argument validations
      if [options[:file], options[:json]].compact.count != 1
        $stderr.puts "ERROR: Only one of `--file` or `--json` option should be specified."
        return -1
      end
      if options[:file]&.empty? or options[:file] == "file" or options[:json]&.empty?
        $stderr.puts "ERROR: --file option require not empty argument."
        return -1
      end
      if options[:json]&.empty? or options[:json] == "json"
        $stderr.puts "ERROR: --json option require not empty argument."
        return -1
      end

      tree = if options[:file]
              src = File.read(options[:file])

              begin
                Yasuri.json2tree(src)
              rescue
                begin
                  Yasuri.yaml2tree(src)
                rescue => e
                  $stderr.puts "ERROR: Failed to convert to yasuri tree `#{options[:file]}`. #{e.message}"
                  return -1
                end
              end
            else
              begin
                Yasuri.json2tree(options[:json])
              rescue => e
                $stderr.puts "ERROR: Failed to convert json to yasuri tree. #{e.message}"
                return -1
              end
            end

      agent = Mechanize.new
      root_page = agent.get(uri)
      result = tree.inject(agent, root_page)

      if result.instance_of?(String)
        puts result
      else
        j result
      end

      return 0
    end
  end
end