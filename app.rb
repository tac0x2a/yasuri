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
