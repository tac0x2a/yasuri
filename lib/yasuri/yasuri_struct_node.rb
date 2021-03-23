
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class StructNode
    include Node
    def inject(agent, page, opt = {}, element = page)
      sub_tags = element.search(@xpath)
      tree = sub_tags.map do |sub_tag|
        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.node_name(child_node.name, opt)
          [child_name, child_node.inject(agent, page, opt, sub_tag)]
        end
        Hash[child_results_kv]
      end
      tree.size == 1 ? tree.first : tree
    end # inject

    def node_type_str
      "struct".freeze
    end
  end
end
