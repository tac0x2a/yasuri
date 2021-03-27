
require_relative 'yasuri_node'

module Yasuri
  module Node
    attr_reader :url, :xpath, :name, :children

    def initialize(xpath, name, children = [], **opt)
      @xpath, @name, @children = xpath, name, children
    end

    def scrape(uri, opt = {})
      retry_count = opt[:retry_count] || Yasuri::DefaultRetryCount
      interval_ms = opt[:interval_ms] || Yasuri::DefaultInterval_ms

      agent = Mechanize.new
      page = Yasuri.with_retry(retry_count, interval_ms) { agent.get(uri) }
      scrape_with_agent(uri, agent, opt)
    end

    def scrape_with_agent(uri, agent, opt = {})
      page = agent.get(uri)
      inject(agent, page, opt)
    end

    def inject(agent, page, opt = {}, element = page)
      fail "#{Kernel.__method__} is not implemented in included class."
    end

    def to_h
      return @xpath if @xpath and @children.empty? and self.opts.values.compact.empty?

      node_hash = {}
      self.opts.each{|k, v| node_hash[k] = v if not v.nil?}

      node_hash[:path] = @xpath if @xpath

      children.each do |child|
        child_node_name = "#{child.node_type_str}_#{child.name}"
        node_hash[child_node_name] = child.to_h
      end

      node_hash
    end

    def opts
      {}
    end

    def node_type_str
      fail "#{Kernel.__method__} is not implemented in included class."
    end
  end
end
