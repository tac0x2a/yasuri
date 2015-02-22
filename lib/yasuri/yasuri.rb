# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'
require 'json'

module Yasuri

  module Node
    attr_reader :url, :xpath, :name

    def initialize(xpath, name, children = [])
      @xpath, @name, @children = xpath, name, children
    end

    def inject(agent, page)
      fail "#{Kernel.__method__} is not implemented."
    end
  end

  class TextNode
    include Node
    def initialize(xpath, name, children = [])
      super(xpath, name, children)
      @truncate_regexp, dummy = *children
    end
    def inject(agent, page)
      node = page.search(@xpath)
      text = node.text.to_s

      text = text[@truncate_regexp, 0] if @truncate_regexp

      text.to_s
    end
  end

  class StructNode
    include Node
    def inject(agent, page)
      sub_tags = page.search(@xpath)
      sub_tags.map do |sub_tag|
        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, sub_tag)]
        end
        Hash[child_results_kv]
      end
    end
  end

  class LinksNode
    include Node
    def inject(agent, page)
      links = page.search(@xpath) || [] # links expected
      links.map do |link|
        link_button = Mechanize::Page::Link.new(link, agent, page)
        child_page = link_button.click

        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, child_page)]
        end

        Hash[child_results_kv]
      end # each named child node
    end
  end

  class PaginateNode
    include Node
    def inject(agent, page)

      child_results = []
      while page
        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, page)]
        end
        child_results << Hash[child_results_kv]

        link = page.search(@xpath).first
        break if link == nil

        link_button = Mechanize::Page::Link.new(link, agent, page)
        page = link_button.click
      end

      child_results
    end
  end

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
      xpath, children = *args
      children = Yasuri::NodeGenerator.new.gen_recursive(&block) if block_given?

      case name
      when /^text_(.+)$/
        truncate_regexp, dummy = children
        Yasuri::TextNode.new(xpath, $1, children || [])
      when /^struct_(.+)$/
        Yasuri::StructNode.new(xpath, $1, children || [])
      when /^links_(.+)$/
        Yasuri::LinksNode.new(xpath, $1, children || [])
      when /^pages_(.+)$/
        Yasuri::PaginateNode.new(xpath, $1, children || [])
      else
        nil
      end
    end # of self.gen(name, *args, &block)
  end # of class NodeGenerator

  def self.json2tree(json_string)
    json = JSON.parse(json_string)
    Yasuri.hash2node(json)
  end

  private
  Text2Node = {
    "text"   => TextNode,
    "struct" => StructNode,
    "links"  => LinksNode,
    "pages"  => PaginateNode
  }
  def self.hash2node(node_h)
    node, name, path, children = %w|node name path children|.map do |key|
      node_h[key]
    end
    children ||= []

    childnodes = children.map{|c| Yasuri.hash2node(c) }

    klass = Text2Node[node]
    klass ? klass.new(path, name, childnodes) : nil
  end
end

# alias for DSL
def method_missing(name, *args, &block)
  generated = Yasuri::NodeGenerator.gen(name, *args, &block)
  generated || super(name, args)
end
