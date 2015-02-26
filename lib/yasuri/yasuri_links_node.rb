
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class LinksNode
    include Node
    def inject(agent, page, retry_count = 5)
      links = page.search(@xpath) || [] # links expected
      links.map do |link|
        link_button = Mechanize::Page::Link.new(link, agent, page)
        child_page = Yasuri.with_retry(retry_count) { link_button.click }

        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, child_page, retry_count)]
        end

        Hash[child_results_kv]
      end # each named child node
    end
  end
end
