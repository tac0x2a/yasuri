
module Yasuri
  class TreeNode
    attr_reader :name, :children

    def initialize(name, children, opt: {})
      @name = name
      @children = children
      @opt = opt
    end

    def inject(agent, page, opt = {}, element = page)
      child_results_kv = @children.map do |node|
        [node.name, node.inject(agent, page, opt)]
      end
      Hash[child_results_kv]
    end
    def opts
      {}
    end
  end
end
