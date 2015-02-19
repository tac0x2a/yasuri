# Yasuri [![Build Status](https://travis-ci.org/tac0x2a/yasuri.svg?branch=master)](https://travis-ci.org/tac0x2a/yasuri) [![Coverage Status](https://coveralls.io/repos/tac0x2a/yasuri/badge.svg?branch=master)](https://coveralls.io/r/tac0x2a/yasuri?branch=master) [![Code Climate](https://codeclimate.com/github/tac0x2a/yasuri/badges/gpa.svg)](https://codeclimate.com/github/tac0x2a/yasuri)

Yasuri (鑢) is an easy web-scraping library for supporting "[Mechanize](https://github.com/sparklemotion/mechanize)".

### Example

```ruby
# Node tree constructing by DSL
root = links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end

# Node tree constructing by JSON
src = <<-EOJSON
   { "node"     : "links",
     "name"     : "root",
     "path"     : "//*[@id='menu']/ul/li/a",
     "children" : [
                    { "node" : "text",
                      "name" : "title",
                      "path" : "//*[@id='contents']/h2"
                    },
                    { "node" : "text",
                      "name" : "content",
                      "path" : "//*[@id='contents']/p[1]"
                    }
                  ]
   }
EOJSON
root = Yasuri.json2tree(src)

agent = Mechanize.new
root_page = agent.get("http://some.scraping.page.net/")

result = root.inject(agent, root_page)
# => [ {"title" => "PageTitle", "content" => "Page Contents" }, ...  ]
```
