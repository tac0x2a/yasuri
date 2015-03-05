# Yasuri Usage

## Basics

1. Construct parse tree.
2. Start parse with Mechanize agent and first page.

### Construct parse tree

```ruby
require 'mechanize'
require 'yasuri'


# 1. Construct parse tree.
tree = Yasuri.links_title '/html/body/a' do
         text_name '/html/body/p'
       end

# 2. Start parse with Mechanize agent and first page.
agent = Mechanize.new
page = agent.get(uri)


tree.inject(agent, page)
```

Tree is definable by 3 ways, basic ruby code, DSL ruby code, and json. In this example, DSL.
