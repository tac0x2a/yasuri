
module Yasuri
  class MapNode
    include Node
    attr_reader :name, :children

    def initialize(name, children, **opt)
      @name = name
      @children = children
      @opt = opt
    end

    def inject(agent, page, opt = {}, _element = page)
      child_results_kv = @children.map do |node|
        [node.name, node.inject(agent, page, opt)]
      end
      Hash[child_results_kv]
    end

    def to_h
      node_hash = {}
      self.opts.each { |k, v| node_hash[k] = v unless v.nil? }

      children.each do |child|
        child_node_name = "#{child.node_type_str}_#{child.name}"
        node_hash[child_node_name] = child.to_h
      end

      node_hash
    end

    def opts
      {}
    end

    def node_type_str
      "map".freeze
    end
  end
end
