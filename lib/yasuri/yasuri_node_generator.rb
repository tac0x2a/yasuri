
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'
require_relative 'yasuri_text_node'
require_relative 'yasuri_struct_node'
require_relative 'yasuri_links_node'
require_relative 'yasuri_paginate_node'
require_relative 'yasuri_map_node'

module Yasuri
  class NodeGenerator
    def gen_recursive(&block)
      @nodes = []
      instance_eval(&block)
      @nodes
    end

    def method_missing(name, pattern=nil, **args, &block)
      node = NodeGenerator.gen(name, pattern, **args, &block)
      raise "Undefined Node Name '#{name}'" if node == nil
      @nodes << node
    end

    def self.gen(method_name, xpath, **opt, &block)
      children = Yasuri::NodeGenerator.new.gen_recursive(&block) if block_given?

      case method_name
      when /^text_(.+)$/
        # Todo raise error xpath is not valid
        Yasuri::TextNode.new(xpath, $1, children || [], **opt)
      when /^struct_(.+)$/
        # Todo raise error xpath is not valid
        Yasuri::StructNode.new(xpath, $1, children || [], **opt)
      when /^links_(.+)$/
        # Todo raise error xpath is not valid
        Yasuri::LinksNode.new(xpath, $1, children || [], **opt)
      when /^pages_(.+)$/
        # Todo raise error xpath is not valid
        Yasuri::PaginateNode.new(xpath, $1, children || [], **opt)
      when /^map_(.+)$/
        Yasuri::MapNode.new($1, children, **opt)
      else
        nil
      end
    end # of self.gen(method_name, xpath, **opt, &block)
  end # of class NodeGenerator
end
