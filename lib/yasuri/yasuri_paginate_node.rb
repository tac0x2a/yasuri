
require_relative 'yasuri_node'

module Yasuri
  class PaginateNode
    include Node

    def initialize(xpath, name, children = [], limit: nil, flatten: false)
      super(xpath, name, children)
      @flatten = flatten
      @limit = limit
    end

    def inject(agent, page, opt = {}, element = page)
      raise NotImplementedError.new("PagenateNode inside StructNode, Not Supported") if page != element

      limit = @limit.nil? ? Float::MAX : @limit
      child_results = inject_child(agent, page, limit, opt)

      return child_results.map(&:values).flatten if @flatten == true

      child_results
    end

    def opts
      { limit: @limit, flatten: @flatten }
    end

    def node_type_str
      "pages".freeze
    end

    private

    def inject_child(agent, page, limit, opt)
      retry_count = opt[:retry_count] || Yasuri::DefaultRetryCount
      interval_ms = opt[:interval_ms] || Yasuri::DefaultInterval_ms

      child_results = []
      while page
        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.node_name(child_node.name, opt)
          [child_name, child_node.inject(agent, page, opt)]
        end
        child_results << Hash[child_results_kv]

        link = page.search(@xpath).first # Todo raise:  link is not found
        break if link.nil?

        link_button = Mechanize::Page::Link.new(link, agent, page)
        page = Yasuri.with_retry(retry_count, interval_ms) { link_button.click }
        break if (limit -= 1) <= 0
      end

      child_results
    end
  end
end
