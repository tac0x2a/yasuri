# Yasuri [![Build Status](https://travis-ci.org/tac0x2a/yasuri.svg?branch=master)](https://travis-ci.org/tac0x2a/yasuri) [![Coverage Status](https://coveralls.io/repos/tac0x2a/yasuri/badge.svg?branch=master)](https://coveralls.io/r/tac0x2a/yasuri?branch=master) [![Code Climate](https://codeclimate.com/github/tac0x2a/yasuri/badges/gpa.svg)](https://codeclimate.com/github/tac0x2a/yasuri)

Yasuri (鑢) is an easy web-scraping library for supporting "[Mechanize](https://github.com/sparklemotion/mechanize)".

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'yasuri'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install yasuri

## Usage

```ruby
# Node tree constructing by DSL
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
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


## Contributing

1. Fork it ( https://github.com/tac0x2a/yasuri/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
