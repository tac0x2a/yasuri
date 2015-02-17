#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# Author::    TAC (tac@tac42.net)

require 'pp'
require 'time'
require 'mechanize'

require_relative 'lib/swim/swim'

agent = Mechanize.new

uri = "http://www.asahi.com/"

root = links_top '//*[@id="MainInner"]/div[1]/ul/li/a' do
  text_title   '//*[@id="MainInner"]/div[1]/div/h1'
  text_article '//*[@id="MainInner"]/div/div[@class="ArticleText"]'
end

page = agent.get(uri)
contents = root.inject(agent, page)

contents.each do |h|
  t = h['title']
  a = h['article']

  puts t
  puts a
  puts "=" * 100
end

# c = Swim::Cond::and( Swim::Cond::Match(/\d/), Swim::Cond::NewerThen() )
# t = Swim::Trigger.new("http://www.tac42.net/", '//*[@id="contents"]/dl/dt/span', c)

# if Swim.trigger(t, agent)
#   root = Swim::LinksNode.new('//*[@id="menu"]/ul/li/a', "root", [
#            Swim::ContentNode.new('//*[@id="contents"]/h2', "title"),
#            Swim::ContentNode.new('//*[@id="contents"]/p[1]', "content"),
#          ]
#   )

#   root_page = agent.get("http://www.tac42.net/")

#   result = root.inject(agent, root_page)
#   result.each do |sub_content|
#     puts sub_content["title"]
#     puts sub_content["content"]
#     puts "--" * 10
#   end
# else
#   puts "page is not modify."
# end
