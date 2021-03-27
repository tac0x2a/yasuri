require 'thor'
require 'json'
require 'yasuri'
require 'mechanize'

module Yasuri
  class CLI < Thor
    package_name "yasuri"

    default_command :scrape
    desc "scrape <URI> [[--file <TREE_FILE>] or [--json <JSON>]]", "Getting from <URI> and scrape it. with <JSON> or json/yml from <TREE_FILE>. They should be Yasuri's format json or yaml string."
    option :file,     {aliases: 'f', desc: "path to file that written yasuri tree as json or yaml", type: :string}
    option :json,     {aliases: 'j', desc: "yasuri tree format json string", type: :string}
    option :interval, {aliases: 'i', desc: "interval each request [ms]", type: :numeric}
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

      interval_ms = options[:interval] || Yasuri::DefaultInterval_ms

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
      result = tree.inject(agent, root_page, interval_ms: interval_ms)

      if result.instance_of?(String)
        puts result
      else
        j result
      end

      return 0
    end
  end
end