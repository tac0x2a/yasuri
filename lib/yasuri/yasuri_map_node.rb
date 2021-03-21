
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

    def to_h
      h = {}
      h["node"] = "map"
      h["name"] = self.name
      h["children"] = self.children.map{|c| c.to_h} if not children.empty?

      self.opts.each do |key,value|
        h[key] = value if not value.nil?
      end

      h
    end

    def self.hash2node(node_h)
      reservedKeys = %i|node name children|

      node, name, children = reservedKeys.map do |key|
        node_h[key]
      end

      fail "Not found 'name' value in map" if name.nil?
      fail "Not found 'children' value in map" if children.nil?
      children ||= []

      childnodes = children.map{|c| Yasuri.hash2node(c) }
      reservedKeys.each{|key| node_h.delete(key)}
      opt = node_h

      self.new(name, childnodes, **opt)
    end
  end
end
