require 'thor'
require 'json'
require 'yasuri'
require 'mechanize'

module Yasuri
  class CLI < Thor
    desc "scrape <URI> <JSON>", "Getting from <URI> and scrape with <JSON>. <JSON> is Yasuri's format json string."
    def scrape(uri, json)
      src = json

      root = Yasuri.json2tree(src)
      agent = Mechanize.new
      root_page = agent.get(uri)
      result = root.inject(agent, root_page)

      if result.instance_of?(String)
        puts result
      else
        j result
      end

      return 0
    end
  end
end