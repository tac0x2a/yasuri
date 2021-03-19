# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'
require 'json'
require 'yaml'

require_relative 'yasuri_node'
require_relative 'yasuri_text_node'
require_relative 'yasuri_struct_node'
require_relative 'yasuri_paginate_node'
require_relative 'yasuri_links_node'
require_relative 'yasuri_node_generator'
require_relative 'yasuri_tree'

module Yasuri

  def self.json2tree(json_string)
    json = JSON.parse(json_string, {symbolize_names: true})
    Yasuri.hash2node(json)
  end

  def self.tree2json(node)
    Yasuri.node2hash(node).to_json
  end

  def self.yaml2tree(yaml_string)
    raise RuntimeError if yaml_string.nil? or yaml_string.empty?

    yaml = YAML.load(yaml_string)
    raise RuntimeError if yaml.keys.size < 1

    root_key, root = yaml.keys.first, yaml.values.first
    hash = Yasuri.yaml2tree_sub(root_key, root)

    Yasuri.hash2node(hash)
  end

  def self.tree(&block)
    node_list = Yasuri::NodeGenerator.new.gen_recursive(&block)
    Yasuri::Tree.new(node_list)
  end

  private
  def self.yaml2tree_sub(name, body)
    return nil if name.nil? or body.nil?

    new_body = Hash[:name, name]
    body.each{|k,v| new_body[k.to_sym] = v}
    body = new_body

    return body if body[:children].nil?

    body[:children] = body[:children].map do |c|
      k, b = c.keys.first, c.values.first
      Yasuri.yaml2tree_sub(k, b)
    end

    body
  end

  def self.method_missing(node_name, pattern, **opt, &block)
    generated = Yasuri::NodeGenerator.gen(node_name, pattern, **opt, &block)
    generated || super(node_name, **opt)
  end

  private
  Text2Node = {
    text:   Yasuri::TextNode,
    struct: Yasuri::StructNode,
    links:  Yasuri::LinksNode,
    pages:  Yasuri::PaginateNode
  }
  Node2Text = Text2Node.invert

  ReservedKeys = %i|node name path children|
  def self.hash2node(node_h)
    node, name, path, children = ReservedKeys.map do |key|
      node_h[key]
    end
    children ||= []

    fail "Not found 'node' value in map" if node.nil?
    fail "Not found 'name' value in map" if name.nil?
    fail "Not found 'path' value in map" if path.nil?

    childnodes = children.map{|c| Yasuri.hash2node(c) }
    ReservedKeys.each{|key| node_h.delete(key)}
    opt = node_h

    klass = Text2Node[node.to_sym]
    fail "Undefined node type #{node}" if klass.nil?
    klass.new(path, name, childnodes, **opt)
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

  def self.NodeName(name, opt)
    symbolize_names = opt[:symbolize_names]
    symbolize_names ? name.to_sym : name
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
