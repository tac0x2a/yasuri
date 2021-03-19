
module Yasuri
  class Tree
    def initialize(node_list, opt: {})
      @node_list = node_list
      @opt = opt
    end

    def inject(agent, page, opt = {}, element = page)
      child_results_kv = @node_list.map do |node|
        [node.name, node.inject(agent, page, opt)]
      end
      Hash[child_results_kv]
    end
    def opts
      {}
    end
  end
end
