#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'mechanize'
require 'pp'
require 'time'

Trigger = Struct.new("Trigger", :url, :xpath, :cond)

@agent = Mechanize.new

def trigger(trigger, agent = @agent)
  page = @agent.get(trigger.url)
  node = page.search(trigger.xpath)
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

# c = Cond::and( Cond::Match(/\d/), Cond::NewerThen() )
c = Cond::Modify("Least read string")
t = Trigger.new("http://iidx.tac42.net/", "/html/body/div/div[2]/h5[8]/text()", c)

begin
  puts trigger(t)
rescue => e
  puts e.message
  pp e
end
