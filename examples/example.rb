#!/usr/bin/env ruby

require 'yasuri'
uri = "https://github.com/tac0x2a?tab=repositories"

# Node tree constructing by DSL
root = Yasuri.map_root do
  text_title '/html/head/title'
  links_repo '//*[@id="user-repositories-list"]/ul/li/div[1]/div[1]/h3/a' do
    text_name '//*[@id="js-repo-pjax-container"]/div[1]/div[1]/div/h1/strong/a'
    text_desc '//*[@id="repo-content-pjax-container"]/div/div[2]/div[2]/div/div[1]/div/p', proc: :strip
    text_stars '//*[@id="js-repo-pjax-container"]/div[1]/div[2]/div[2]/a[1]', proc: :to_i
    text_forks '//*[@id="js-repo-pjax-container"]/div[1]/div[2]/div[2]/a[2]/span', proc: :to_i
  end
end

# Node tree constructing by YAML
# src = <<-EOYML
# text_title: /html/head/title
# links_repo:
#   path: //*[@id="user-repositories-list"]/ul/li/div[1]/div[1]/h3/a
#   text_name: //*[@id="js-repo-pjax-container"]/div[1]/div[1]/div/h1/strong/a
#   text_desc:
#     path: //*[@id="repo-content-pjax-container"]/div/div[2]/div[2]/div/div[1]/div/p
#     proc: :strip
#   text_stars:
#     path: //*[@id="js-repo-pjax-container"]/div[1]/div[2]/div[2]/a[1]
#     proc: :to_i
#   text_forks:
#     path: //*[@id="js-repo-pjax-container"]/div[1]/div[2]/div[2]/a[2]/span
#     proc: :to_i
# EOYML
# root = Yasuri.yaml2tree(src)

contents = root.scrape(uri, interval_ms: 100)
# jj contents
# {
#   "title": "tac0x2a (TAC) / Repositories · GitHub",
#   "repo": [
#     {
#       "name": "o-namazu",
#       "desc": "Oh Namazu (Catfish) in datalake",
#       "stars": 1,
#       "forks": 0
#     },
#     {
#       "name": "grebe",
#       "desc": "grebe in datalake",
#       "stars": 2,
#       "forks": 0
#     },
#     {
#       "name": "yasuri",
#       "desc": "Yasuri (鑢) is easy web scraping library.",
#       "stars": 43,
#       "forks": 1
#     },
#     {
#       "name": "dotfiles",
#       "desc": "dotfiles",
#       "stars": 0,
#       "forks": 0
#     }
#     ...
#   ]
# }

# Output as markdown
puts "# #{contents['title']}"
contents['repo'].each do |h|
  puts "-----"
  puts "## #{h['name']}"
  puts h['desc']
  puts ""
  puts "* Stars: #{h['stars']}"
  puts "* Forks: #{h['forks']}"
  puts ""
end
