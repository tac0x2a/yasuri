
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class StructNode
    include Node
    def inject(agent, page, opt:{})
      retry_count = opt[:retry_count] || 5

      sub_tags = page.search(@xpath)
      sub_tags.map do |sub_tag|
        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, sub_tag, opt)]
        end
        Hash[child_results_kv]
      end
    end
  end
end
