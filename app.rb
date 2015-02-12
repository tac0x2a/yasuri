#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'pp'
require 'time'

require_relative 'lib/swim/swim'

@agent = Mechanize.new

# c = Swim::Cond::and( Cond::Match(/\d/), Cond::NewerThen() )
c = Swim::Cond::Modify("2月11日 19時04分")
t = Swim::Trigger.new("http://www3.nhk.or.jp/news/", "//*[@id='topttl']/a/span", c)

begin
  puts Swim.trigger(t, @agent)
rescue => e
  puts e.message
  pp e
end


root = Swim::LinksNode.new('//*[@id="menu"]/ul/li/a', "root", [
         Swim::ContentNode.new('//*[@id="contents"]/h2', "title"),
         Swim::ContentNode.new('//*[@id="contents"]/p[1]', "content"),
       ]
)

root_page = @agent.get("http://www.tac42.net/")
result = root.inject(@agent, root_page)
result.each.with_index do |l, idx|
  puts l["title"]
  puts l["content"]
  puts "--" * 10
end
