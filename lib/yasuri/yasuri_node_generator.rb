
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'
require_relative 'yasuri_text_node'
require_relative 'yasuri_struct_node'
require_relative 'yasuri_links_node'
require_relative 'yasuri_paginate_node'

module Yasuri
  class NodeGenerator
    def gen_recursive(&block)
      @nodes = []
      instance_eval(&block)
      @nodes
    end

    def method_missing(name, pattern, **args, &block)
      node = NodeGenerator.gen(name, pattern, **args, &block)
      raise "Undefined Node Name '#{name}'" if node == nil
      @nodes << node
    end

    def self.gen(name, xpath, **opt, &block)
      children = Yasuri::NodeGenerator.new.gen_recursive(&block) if block_given?

      case name
      when /^text_(.+)$/
        Yasuri::TextNode.new(xpath,   $1, children || [], **opt)
      when /^struct_(.+)$/
        Yasuri::StructNode.new(xpath, $1, children || [], **opt)
      when /^links_(.+)$/
        Yasuri::LinksNode.new(xpath,  $1, children || [], **opt)
      when /^pages_(.+)$/
        Yasuri::PaginateNode.new(xpath, $1, children || [], **opt)
      else
        nil
      end
    end # of self.gen(name, *args, &block)
  end # of class NodeGenerator
end
