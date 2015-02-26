
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

    def method_missing(name, *args, &block)
      node = NodeGenerator.gen(name, *args, &block)
      raise "Undefined Node Name '#{name}'" if node == nil
      @nodes << node
    end

    def self.gen(name, *args, &block)
      xpath, opt = *args
      opt = [opt].flatten.compact
      children = Yasuri::NodeGenerator.new.gen_recursive(&block) if block_given?

      case name
      when /^text_(.+)$/
        truncate, dummy = *opt
        Yasuri::TextNode.new(xpath,   $1, children || [], truncate: truncate)
      when /^struct_(.+)$/
        Yasuri::StructNode.new(xpath, $1, children || [])
      when /^links_(.+)$/
        Yasuri::LinksNode.new(xpath,  $1, children || [])
      when /^pages_(.+)$/
        limit, dummy = *opt
        limit = limit || Float::MAX
        Yasuri::PaginateNode.new(xpath, $1, children || [], limit: limit)
      else
        nil
      end
    end # of self.gen(name, *args, &block)
  end # of class NodeGenerator
end
