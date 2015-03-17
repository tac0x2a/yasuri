# Yasuri Usage

## Quick Start

```
$ gem install yasuri
```

```ruby
require 'yasuri'
require 'machinize'

# Node tree constructing by DSL
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end

agent = Mechanize.new
root_page = agent.get("http://some.scraping.page.net/")

result = root.inject(agent, root_page)
# => [ {"title" => "PageTitle1", "content" => "Page Contents1" },
#      {"title" => "PageTitle2", "content" => "Page Contents2" }, ...  ]

```
This example, from the pages of each link that is expressed by the xpath of LinkNode(`links_root`), to scraping the two text that is expressed by the xpath of TextNode(`text_title`,`text_content`).

(i.e. open each links `//*[@id="menu"]/ul/li/a` and, scrape `//*[@id="contents"]/h2` and `//*[@id="contents"]/p[1]`.)

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

Tree is definable by 2(+1) ways, DSL, json, (and basic ruby code). In above example, DSL.

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
Node has `Type`, `Name`, `Path`, `Childlen`, and `Options`.

Node is defined by this format.


```ruby
# Top Level
Yasuri.<Type>_<Name> <Path> [,<Options>]

# Nested
Yasuri.<Type>_<Name> <Path> [,<Options>] do
  <Type>_<Name> <Path> [,<Options>] do
    <Children>
  end
end
```

#### Type
Type meen behavior of Node.

- *Text*
- *Structure*
- *Links*
- *Paginate*

### Name
Name is used keys in returned hash.

### Path
Path determine target node by xpath or ccs selector. It given by Machinize `search`.

### Childlen
Child nodes. TextNode has always empty set, because TextNode is leaf.

### Options
Parse options. It different in each types.

## TextNode
TextNode return scraped text. This node have to be leaf.

Example

```html:http://yasuri.example.net
<html>
  <head></head>
  <body>
    <p>Hello,World</p>
    <p>Hello,Yasuri</p>
  </body>
</html>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net")

p1  = Yasuri.text_title '/html/body/p[1]'
p1t = Yasuri.text_title '/html/body/p[1]', truncate:/^[^,]+/
p2u = Yasuri.text_title '/html/body/p[2]', proc: :upcase

p1.inject(agent, page)   #=> { "title" => "Hello,World" }
p1t.inject(agent, page)  #=> { "title" => "Hello" }
node.inject(agent, page) #=> { "title" => "HELLO,YASURI" }
```

### Options
