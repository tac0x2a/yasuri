# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'
require 'json'

require_relative 'yasuri_node'
require_relative 'yasuri_text_node'
require_relative 'yasuri_struct_node'
require_relative 'yasuri_paginate_node'
require_relative 'yasuri_links_node'
require_relative 'yasuri_node_generator'

module Yasuri

  def self.json2tree(json_string)
    json = JSON.parse(json_string)
    Yasuri.hash2node(json)
  end

  def self.tree2json(node)
    Yasuri.node2hash(node).to_json
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
