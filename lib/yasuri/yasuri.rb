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
require_relative 'yasuri_map_node'
require_relative 'yasuri_node_generator'

module Yasuri

  def self.json2tree(json_string)
    raise RuntimeError if json_string.nil? or json_string.empty?

    node_hash = JSON.parse(json_string, {symbolize_names: true})
    Yasuri.hash2node(node_hash)
  end

  def self.tree2json(node)
    Yasuri.node2hash(node).to_json
  end

  def self.yaml2tree(yaml_string)
    raise RuntimeError if yaml_string.nil? or yaml_string.empty?

    yaml = YAML.load(yaml_string)
    raise RuntimeError if yaml.keys.size < 1

    root_key, root = yaml.keys.first, yaml.values.first
    node_hash = Yasuri.yaml2tree_sub(root_key, root)

    Yasuri.hash2node(node_hash)
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

  def self.method_missing(method_name, pattern=nil, **opt, &block)
    generated = Yasuri::NodeGenerator.gen(method_name, pattern, **opt, &block)
    generated || super(method_name, **opt)
  end

  private
  Text2Node = {
    text:   Yasuri::TextNode,
    struct: Yasuri::StructNode,
    links:  Yasuri::LinksNode,
    pages:  Yasuri::PaginateNode,
    map:    Yasuri::MapNode
  }

  def self.hash2node(node_hash)
    node = node_hash[:node]

    fail "Not found 'node' value in map" if node.nil?
    klass = Text2Node[node.to_sym]
    klass::hash2node(node_hash)
  end

  def self.node2hash(node)
    node.to_h
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
