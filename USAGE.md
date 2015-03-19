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
- *Struct*
- *Links*
- *Paginate*

### Name
Name is used keys in returned hash.

### Path
Path determine target node by xpath or ccs selector. It given by Machinize `search`.

### Childlen
Child nodes. TextNode has always empty set, because TextNode is leaf.

### Options
Parse options. It different in each types. You can get options and values by `opt` method.

```
# TextNode Exaample
node = Yasuri.text_title '/html/body/p[1]', truncate:/^[^,]+/
node.opt #=> {:truncate => /^[^,]+/, :proc => nil}
```

## Text Node
TextNode return scraped text. This node have to be leaf.

### Example

```html
<!-- http://yasuri.example.net -->
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
##### `truncate`
Match to regexp, and truncate text. When you use group, it will return first matched group only.

```ruby
node  = Yasuri.text_example '/html/body/p[1]', truncate:/H(.+)i/
node.inject(agent, index_page)
#=> { "example" => "ello,Yasur" }
```


##### `proc`
Apply method to text. Method is given as Symbol.
If it is given `truncate` option, apply method after truncated.

```ruby
node = Yasuri.text_example '/html/body/p[1]', proc: :upcase, truncate:/H(.+)i/
node.inject(agent, index_page)
#=> { "example" => "ELLO,YASUR" }
```

## Struct Node
Struct Node return structured text.

At first, Struct Node narrow down sub-tags by `Path`. Child nodes parse narrowed tags, and struct node returns hash contains parsed result.

If Struct Node `Path` matches multi sub-tags, child nodes parse each sub-tags and struct node returns array.

### Example

```
<!-- http://yasuri.example.net -->
<html>
  <head>
    <title>Books</title>
  </head>
  <body>
    <h1>1996</h1>
    <table>
      <thead>
        <tr><th>Title</th> <th>Publication Date</th></tr>
      </thead>
      <tr><td>The Perfect Insider</td>      <td>1996/4/5</td></tr>
      <tr><td>Doctors in Isolated Room</td> <td>1996/7/5</td></tr>
      <tr><td>Mathematical Goodbye</td>     <td>1996/9/5</td></tr>
    </table>

    <h1>1997</h1>
    <table>
      <thead>
        <tr><th>Title</th> <th>Publication Date</th></tr>
      </thead>
      <tr><td>Jack the Poetical Private</td> <td>1997/1/5</td></tr>
      <tr><td>Who Inside</td>                <td>1997/4/5</td></tr>
      <tr><td>Illusion Acts Like Magic</td>  <td>1997/10/5</td></tr>
    </table>

    <h1>1998</h1>
    <table>
      <thead>
        <tr><th>Title</th> <th>Publication Date</th></tr>
      </thead>
      <tr><td>Replaceable Summer</td>   <td>1998/1/7</td></tr>
      <tr><td>Switch Back</td>          <td>1998/4/5</td></tr>
      <tr><td>Numerical Models</td>     <td>1998/7/5</td></tr>
      <tr><td>The Perfect Outsider</td> <td>1998/10/5</td></tr>
    </table>
  </body>
</html>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net")

node = Yasuri.struct_table '/html/body/table[1]/tr' do
  text_title    './td[1]'
  text_pub_date './td[2]'
])

node.inject(agent, page)
#=> [ { "title"    => "The Perfect Insider",
#       "pub_date" => "1996/4/5" },
#     { "title"    => "Doctors in Isolated Room",
#       "pub_date" => "1996/7/5" },
#     { "title"    => "Mathematical Goodbye",
#       "pub_date" => "1996/9/5" }, ]
```

StructNode narrow down `<tr>` tags in first `<table>` by `'/html/body/table[1]/tr'`. Then,
`<tr>` tags parsed Struct node has two child node.

In this case, first `<table>` contains three `<tr>` tags (Not four.`<thead><tr>` is not match to `Path` ), so struct node returns three hashes. Each hash contains parsed text by Text Node.

Struct node can contain not only Text node.

### Example

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net")

node = Yasuri.strucre_tables '/html/body/table' do
  struct_table './tr' do
    text_title    './td[1]'
    text_pub_date './td[2]'
  end
])

node.inject(agent, page)

#=>      [ { "table" => [ { "title"    => "The Perfect Insider",
#                           "pub_date" => "1996/4/5" },
#                         { "title"    => "Doctors in Isolated Room",
#                           "pub_date" => "1996/7/5" },
#                         { "title"    => "Mathematical Goodbye",
#                           "pub_date" => "1996/9/5" }]},
#          { "table" => [ { "title"    => "Jack the Poetical Private",
#                           "pub_date" => "1997/1/5" },
#                         { "title"    => "Who Inside",
#                           "pub_date" => "1997/4/5" },
#                         { "title"    => "Illusion Acts Like Magic",
#                           "pub_date" => "1997/10/5" }]},
#          { "table" => [ { "title"    => "Replaceable Summer",
#                           "pub_date" => "1998/1/7" },
#                         { "title"    => "Switch Back",
#                           "pub_date" => "1998/4/5" },
#                         { "title"    => "Numerical Models",
#                           "pub_date" => "1998/7/5" },
#                         { "title"    => "The Perfect Outsider",
#                           "pub_date" => "1998/10/5" }]}
#       ]
```

### Options
None.