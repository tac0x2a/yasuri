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


```ruby
# Construct by json.
src = <<-EOJSON
   { "node"     : "links",
     "name"     : "title",
     "path"     : "/html/body/a",
     "children" : [
                    { "node" : "text",
                      "name" : "name",
                      "path" : "/html/body/p"
                    }
                  ]
   }
EOJSON
tree = Yasuri.json2tree(src)
```

### Node
Tree is constructed by nested Nodes.
Node has `Type`, `Name`, `Path`, `Childlen`, and some `Options`.


#### Type
Type meen behavior of Node.

- Text
- Structure
- Links
- Paginate

## TextNode

Example

```ruby
node = Yasuri.text_title '/html/body/p[1]', truncate:/^hoge/
```
