
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
  DefaultInterval_ms = 0

  def self.json2tree(json_string)
    raise RuntimeError if json_string.nil? or json_string.empty?

    node_hash = JSON.parse(json_string, {symbolize_names: true})
    self.hash2node(node_hash)
  end

  def self.yaml2tree(yaml_string)
    raise RuntimeError if yaml_string.nil? or yaml_string.empty?

    node_hash = YAML.safe_load(yaml_string, [Symbol], symbolize_names: true)
    self.hash2node(node_hash.deep_symbolize_keys)
  end

  def self.tree2json(node)
    raise RuntimeError if node.nil?

    self.node2hash(node).to_json
  end

  def self.with_retry(
    retry_count = DefaultRetryCount,
    interval_ms = DefaultInterval_ms)

    begin
      Kernel.sleep(interval_ms * 0.001)
      return yield() if block_given?
    rescue => e
      if retry_count > 0
        retry_count -= 1
        retry
      end
      fail e
    end
  end

  def self.node_name(name, opt)
    symbolize_names = opt[:symbolize_names]
    symbolize_names ? name.to_sym : name
  end

  # private

  def self.hash2node(node_hash, node_name = nil, node_type_class = nil)
    raise RuntimeError.new("") if node_name.nil? and node_hash.empty?

    child_nodes = []
    opt = {}
    path = nil

    if node_hash.is_a?(String)
      path = node_hash
    else
      child_nodes, opt, path = self.hash2child_node(node_hash)
    end

    # If only single node under root, return only the node.
    return child_nodes.first if node_name.nil? and child_nodes.size == 1

    node = if node_type_class.nil?
      Yasuri::MapNode.new(node_name, child_nodes, **opt)
    else
      node_type_class::new(path, node_name, child_nodes, **opt)
    end

    node
  end

  Text2Node = {
    text:   Yasuri::TextNode,
    struct: Yasuri::StructNode,
    links:  Yasuri::LinksNode,
    pages:  Yasuri::PaginateNode,
    map:    Yasuri::MapNode
  }

  NodeRegexps = Text2Node.keys.map { |node_type_sym| /^(#{node_type_sym})_(.+)$/ }

  def self.hash2child_node(node_hash)
    child_nodes = []
    opt = {}
    path = nil

    node_hash.each do |key, value|
      # is node?

      node_regexp = NodeRegexps.find { |r| key =~ r }

      case key
      when node_regexp
        node_type_sym = $1.to_sym
        child_node_name = $2
        child_node_type = Text2Node[node_type_sym]
        child_nodes << self.hash2node(value, child_node_name, child_node_type)
      when :path
        path = value
      else
        opt[key] = value
      end
    end

    [child_nodes, opt, path]
  end

  def self.node2hash(node)
    return node.to_h if node.instance_of?(Yasuri::MapNode)

    {
      "#{node.node_type_str}_#{node.name}" => node.to_h
    }
  end

  def self.method_missing(method_name, pattern=nil, **opt, &block)
    generated = Yasuri::NodeGenerator.gen(method_name, pattern, **opt, &block)
    generated || super(method_name, **opt)
  end

  private_constant :Text2Node, :NodeRegexps
  private_class_method :method_missing, :hash2child_node, :hash2node, :node2hash
end

class Hash
  def deep_symbolize_keys
    Hash[
      self.map do |k, v|
        v = v.deep_symbolize_keys if v.kind_of?(Hash)
        [k.to_sym, v]
      end
    ]
  end
end
