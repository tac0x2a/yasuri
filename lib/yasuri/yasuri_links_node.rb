
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class LinksNode
    include Node
    def inject(agent, page, opt = {}, element = page)
      retry_count = opt[:retry_count] || Yasuri::DefaultRetryCount

      links = element.search(@xpath) || [] # links expected
      links.map do |link|
        link_button = Mechanize::Page::Link.new(link, agent, page)
        child_page = Yasuri.with_retry(retry_count) { link_button.click }

        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.NodeName(child_node.name, opt)
          [child_name, child_node.inject(agent, child_page, opt)]
        end

        Hash[child_results_kv]
      end # each named child node
    end

    def node_type_str
      "links".freeze
    end
  end # class
end # module
