# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'

module Swim

  class Node
    attr_reader :url, :xpath, :name

    def initialize(xpath, name, children = [])
      @xpath, @name, @children = xpath, name, children
    end

    def inject(agent, page)
      fail "#{Kernel.__method__} is not implemented."
    end

  end

  class ContentNode < Node
    def inject(agent, page)
      node = page.search(@xpath)
      node.text.to_s
    end
  end

  class StructNode < Node
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

  class LinksNode < Node
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

  class PaginateNode < Node
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

  class RecursiveNodeGenerator
    def gen_recursive(&block)
      @nodes = []
      instance_eval(&block)
      @nodes
    end

    def method_missing(name, *args, &block)
      case name
      when /^text_(.+)$/
        xpath, children = *args
        @nodes << Swim::ContentNode.new(xpath, $1, children)
        return

      when /^struct_(.+)$/
        xpath, children = *args
        children = Swim::RecursiveNodeGenerator.new.gen_recursive(&block) if block_given?
        @nodes << Swim::StructNode.new(xpath, $1, children || [])
        return

      when /^links_(.+)$/
        xpath, children = *args
        children = Swim::RecursiveNodeGenerator.new.gen_recursive(&block) if block_given?
        @nodes << Swim::LinksNode.new(xpath, $1, children || [])
        return
      end

      raise "Undefined Node Name '#{name}'"
    end
  end
end

# alias for DSL
def method_missing(name, *args, &block)
  case name
  when /^text_(.+)$/
    xpath, children = *args
    return Swim::ContentNode.new(xpath, $1, children)

  when /^struct_(.+)$/
    xpath, children = *args
    children = Swim::RecursiveNodeGenerator.new.gen_recursive(&block) if block_given?
    return Swim::StructNode.new(xpath, $1, children)

  when /^links_(.+)$/
    xpath, children = *args
    children = Swim::RecursiveNodeGenerator.new.gen_recursive(&block) if block_given?
    return Swim::LinksNode.new(xpath, $1, children || [])

  when /^pages_(.+)$/
    xpath, children = *args
    children = Swim::RecursiveNodeGenerator.new.gen_recursive(&block) if block_given?
    return Swim::PaginateNode.new(xpath, $1, children || [])
  end

  super(name, args)
end
