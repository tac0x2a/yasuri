
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
      return @xpath if @xpath and @children.empty? and self.opts.values.compact.empty?

      node_hash = {}
      self.opts.each{|k, v| node_hash[k] = v if not v.nil?}

      node_hash[:path] = @xpath if @xpath

      children.each do |child|
        child_node_name = "#{child.node_type_str}_#{child.name}"
        node_hash[child_node_name] = child.to_h
      end

      node_hash
    end

    module ClassMethods
      def hash2node(node_h)
        reserved_keys = %i|node name path children|

        node, name, path, children = reserved_keys.map do |key|
          node_h[key]
        end

        fail "Not found 'name' value in map" if name.nil?
        fail "Not found 'path' value in map" if path.nil?
        children ||= []

        childnodes = children.map{|c| Yasuri.hash2node(c) }
        reserved_keys.each{|key| node_h.delete(key)}
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
