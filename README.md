# swim
[![Build Status](https://travis-ci.org/tac0x2a/swim.svg?branch=master)](https://travis-ci.org/tac0x2a/swim)
[![Coverage Status](https://coveralls.io/repos/tac0x2a/swim/badge.svg?branch=master)](https://coveralls.io/r/tac0x2a/swim?branch=master)
[![Code Climate](https://codeclimate.com/github/tac0x2a/swim/badges/gpa.svg)](https://codeclimate.com/github/tac0x2a/swim)

swim is easy scraping library by xpath.

### Example

```
# Node tree
root_node = Swim::LinksNode.new('//*[@id="menu"]/ul/li/a', "root", [
              Swim::ContentNode.new('//*[@id="contents"]/h2', "title"),
              Swim::ContentNode.new('//*[@id="contents"]/p[1]', "content"),
            ])

agent = Mechanize.new
root_page = agent.get("http://some.scraping.page.net/")

result = root.inject(agent, root_page)
# => [ {"title" => "PageTitle", "content" => "Page Contents" }, ...  ]
```
