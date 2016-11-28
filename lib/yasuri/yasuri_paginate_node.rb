
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class PaginateNode
    include Node

    def initialize(xpath, name, children = [], limit: nil)
      super(xpath, name, children)
      @limit = limit
    end

    def inject(agent, page, opt = {}, element = page)
      retry_count = opt[:retry_count] || 5

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

      child_results
    end
    def opts
      {limit:@limit}
    end
  end
end
