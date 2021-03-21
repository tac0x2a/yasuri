
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  module Node
    attr_reader :url, :xpath, :name, :children

    def initialize(xpath, name, children = [], opt: {})
      @xpath, @name, @children = xpath, name, children
    end

    def inject(agent, page, opt = {}, element = page)
      fail "#{Kernel.__method__} is not implemented in included class."
    end

    def opts
      {}
    end

    def to_h
      h = {}
      h["node"] = self.node_type_str
      h["name"] = self.name
      h["path"] = self.xpath
      h["children"] = self.children.map{|c| c.to_h} if not children.empty?

      self.opts.each do |key,value|
        h[key] = value if not value.nil?
      end

      h
    end

    module ClassMethods
      def hash2node(node_h)
        reservedKeys = %i|node name path children|

        node, name, path, children = ReservedKeys.map do |key|
          node_h[key]
        end

        fail "Not found 'name' value in map" if name.nil?
        fail "Not found 'path' value in map" if path.nil?
        children ||= []

        childnodes = children.map{|c| Yasuri.hash2node(c) }
        reservedKeys.each{|key| node_h.delete(key)}
        opt = node_h

        self.new(path, name, childnodes, **opt)
      end

      def node_type_str
        fail "#{Kernel.__method__} is not implemented in included class."
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
