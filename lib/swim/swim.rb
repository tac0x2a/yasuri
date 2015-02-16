# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'

module Swim
  Trigger = Struct.new("Trigger", :url, :xpath, :cond)

  ###########
  # trigger #
  ###########
  module_function
  def trigger(trigger, agent)
    page = agent.get(trigger.url)
    node = page.search(trigger.xpath).text
    trigger.cond.(node.to_s)
  end

  module Cond
    True       = lambda{|node| true }
    False      = lambda{|node| false }

    module_function
    def NewerThen(time = Time.now); lambda{|node| Time.parse(node) > time }; end
    def OlderThen(time = Time.now); lambda{|node| Time.parse(node) < time }; end
    def Modify(last); lambda{|node| node != last }; end
    def Match(pattern); lambda{|node| node =~ pattern }; end

    def and(*cond)
      lambda{|node| cond.all?{|c| c.(node)}}
    end
    def or(*cond)
      lambda{|node| cond.any?{|c| c.(node)}}
    end
    def not(cond)
      lambda{|node| not cond.(node) }
    end
  end


  ########
  # Node #
  ########
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

  class LinkNodeGenerator
    def gen_recursive(&block)
      @nodes = []
      instance_eval(&block)
      @nodes
    end

    def method_missing(name, *args, &block)
      case name
      when /^content_node_(.+)$/
        xpath, children = *args
        @nodes << Swim::ContentNode.new(xpath, $1, children)
        return

      when /^link_node_(.+)$/
        xpath, children = *args
        children = Swim::LinkNodeGenerator.new.gen_recursive(&block) if block_given?
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
  when /^content_node_(.+)$/
    xpath, children = *args
    return Swim::ContentNode.new(xpath, $1, children)

  when /^link_node_(.+)$/
    xpath, children = *args
    children = Swim::LinkNodeGenerator.new.gen_recursive(&block) if block_given?
    return Swim::LinksNode.new(xpath, $1, children || [])
  end

  super(name, args)
end
