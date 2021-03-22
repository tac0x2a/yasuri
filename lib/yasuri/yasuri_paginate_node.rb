
# Author::    TAC (tac@tac42.net)

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
      retry_count = opt[:retry_count] || Yasuri::DefaultRetryCount

      raise NotImplementedError.new("PagenateNode inside StructNode, Not Supported") if page != element

      child_results = []
      limit = @limit.nil? ? Float::MAX : @limit
      while page
        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.NodeName(child_node.name, opt)
          [child_name, child_node.inject(agent, page, opt)]
        end
        child_results << Hash[child_results_kv]

        link = page.search(@xpath).first
        break if link == nil

        link_button = Mechanize::Page::Link.new(link, agent, page)
        page = Yasuri.with_retry(retry_count) { link_button.click }
        break if (limit -= 1) <= 0
      end

      if @flatten == true
        return child_results.map{|h| h.values}.flatten
      end

      child_results
    end

    def opts
      {limit:@limit, flatten:@flatten}
    end

    def node_type_str
      "pages".freeze
    end
  end
end
