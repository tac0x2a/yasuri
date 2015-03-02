
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class StructNode
    include Node
    def inject(agent, page, opt = {})
      sub_tags = page.search(@xpath)
      tree = sub_tags.map do |sub_tag|
        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.NodeName(child_node.name, opt)
          [child_name, child_node.inject(agent, sub_tag, opt)]
        end
        Hash[child_results_kv]
      end
      tree.size == 1 ? tree.first : tree
    end # inject
  end
end
