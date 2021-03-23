
module Yasuri
  class MapNode
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

    def node_type_str
      "map".freeze
    end

    def to_h
      node_hash = {}
      self.opts.each{|k, v| node_hash[k] = v if not v.nil?}

      children.each do |child|
        child_node_name = "#{child.node_type_str}_#{child.name}"
        node_hash[child_node_name] = child.to_h
      end

      node_hash
    end

    def self.hash2node(node_hash)
      reserved_keys = %i|node name children|.freeze

      node, name, children = reserved_keys.map{|key| node_hash[key]}

      fail "Not found 'name' value in map" if name.nil?
      fail "Not found 'children' value in map" if children.nil?
      children ||= []

      childnodes = children.map{|c| Yasuri.hash2node(c) }
      reserved_keys.each{|key| node_hash.delete(key)}
      opt = node_hash

      self.new(name, childnodes, **opt)
    end
  end
end
