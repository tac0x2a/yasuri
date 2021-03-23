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

  DefaultRetryCount = 5

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

  def self.hash2node(node_hash, node_name = nil, node_type_class = nil)
    raise RuntimeError.new("") if node_name.nil? and node_hash.empty?

    node_prefixes = Text2Node.keys.freeze
    child_nodes = []
    opt = {}
    path = nil

    if node_hash.is_a?(String)
      path = node_hash
    else
      node_hash.each do |key, value|
        # is node?
        node_regexps = Text2Node.keys.map do |node_type_sym|
          /^(#{node_type_sym.to_s})_(.+)$/
        end
        node_regexp = node_regexps.find do |node_regexp|
          key =~ node_regexp
        end

        case key
        when node_regexp
          node_type_sym = $1.to_sym
          child_node_name = $2
          child_node_type = Text2Node[node_type_sym]
          child_nodes << hash2node(value, child_node_name, child_node_type)
        when :path
          path = value
        else
          opt[key] = value
        end
      end
    end

    # p "--------------------"
    # p "NodeHash #{node_hash}"
    # p "NodeTypeClass #{node_type_class}"
    # p "NodeName #{node_name}"
    # p "Path #{path}"
    # p "Children #{child_nodes}"
    # p "**opt #{opt}"

    # If only single node under root, return only the node.
    return child_nodes.first if node_name.nil? and child_nodes.size == 1

    node = if node_type_class.nil?
      Yasuri::MapNode.new(node_name, child_nodes, **opt)
    else
      node_type_class::new(path, node_name, child_nodes, **opt)
    end

    node
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
