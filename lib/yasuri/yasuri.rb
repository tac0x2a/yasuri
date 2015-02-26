# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'
require 'json'

module Yasuri

  module Node
    attr_reader :url, :xpath, :name, :children

    def initialize(xpath, name, children = [], opt: {})
      @xpath, @name, @children = xpath, name, children
    end

    def inject(agent, page)
      fail "#{Kernel.__method__} is not implemented."
    end
    def opts
      {}
    end
  end

  class TextNode
    include Node
    def initialize(xpath, name, children = [], truncate: nil, opt: {})
      super(xpath, name, children)

      truncate_opt = opt["truncate"] #str
      truncate_opt = Regexp.new(truncate_opt) if not truncate_opt.nil? # regexp or nil

      @truncate = truncate || truncate_opt || nil # regexp or nil

      @truncate = Regexp.new(@truncate.to_s) if not @truncate.nil?

    end
    def inject(agent, page, retry_count = 5)
      node = page.search(@xpath)
      text = node.text.to_s

      text = text[@truncate, 0] if @truncate

      text.to_s
    end
    def opts
      {truncate:@truncate}
    end
  end

  class StructNode
    include Node
    def inject(agent, page, retry_count = 5)
      sub_tags = page.search(@xpath)
      sub_tags.map do |sub_tag|
        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, sub_tag, retry_count)]
        end
        Hash[child_results_kv]
      end
    end
  end

  class LinksNode
    include Node
    def inject(agent, page, retry_count = 5)
      links = page.search(@xpath) || [] # links expected
      links.map do |link|
        link_button = Mechanize::Page::Link.new(link, agent, page)
        child_page = Yasuri.with_retry(retry_count) { link_button.click }

        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, child_page, retry_count)]
        end

        Hash[child_results_kv]
      end # each named child node
    end
  end

  class PaginateNode
    include Node

    def initialize(xpath, name, children = [], limit: nil, opt: {})
      super(xpath, name, children)
      @limit = limit || opt["limit"]
    end

    def inject(agent, page, retry_count = 5)

      child_results = []
      limit = @limit.nil? ? Float::MAX : @limit
      while page
        child_results_kv = @children.map do |child_node|
          [child_node.name, child_node.inject(agent, page, retry_count)]
        end
        child_results << Hash[child_results_kv]

        link = page.search(@xpath).first
        break if link == nil

        link_button = Mechanize::Page::Link.new(link, agent, page)
        page = Yasuri.with_retry(retry_count) { link_button.click }
        break if (limit -= 1) <= 0
      end

      child_results
    end
    def opts
      {limit:@limit}
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

  def self.json2tree(json_string)
    json = JSON.parse(json_string)
    Yasuri.hash2node(json)
  end

  def self.tree2json(node)
    Yasuri.node2hash(node)
  end

  def self.method_missing(name, *args, &block)
    generated = Yasuri::NodeGenerator.gen(name, *args, &block)
    generated || super(name, args)
  end

  private
  Text2Node = {
    "text"   => Yasuri::TextNode,
    "struct" => Yasuri::StructNode,
    "links"  => Yasuri::LinksNode,
    "pages"  => Yasuri::PaginateNode
  }
  Node2Text = Text2Node.invert

  ReservedKeys = %w|node name path children|
  def self.hash2node(node_h)
    node, name, path, children = ReservedKeys.map do |key|
      node_h[key]
    end
    children ||= []

    childnodes = children.map{|c| Yasuri.hash2node(c) }
    ReservedKeys.each{|key| node_h.delete(key)}
    opt = node_h

    klass = Text2Node[node]
    klass ? klass.new(path, name, childnodes, opt: opt) : nil
  end

  def self.node2hash(node)
    json = JSON.parse("{}")
    return json if node.nil?

    klass = node.class
    klass_str = Node2Text[klass]

    json["node"] = klass_str
    json["name"] = node.name
    json["path"] = node.xpath

    children = node.children.map{|c| Yasuri.node2hash(c)}
    json["children"] = children if not children.empty?

    node.opts.each do |key,value|
      json[key] = value if not value.nil?
    end

    json
  end

  def self.with_retry(retry_count = 5)
    begin
      return yield() if block_given?
    rescue => e
      if retry_count > 0
        pp "retry #{retry_count}"
        retry_count -= 1
        retry
      end
      fail e
    end
  end
end
