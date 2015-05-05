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

Tree is definable by 2(+1) ways, DSL and json (and basic ruby code). In above example, DSL.

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

```ruby
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

```html
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

## Links Node
Links Node returns parsed text in each linked pages.

### Example
```html
<!-- http://yasuri.example.net -->
<html>
  <head><title>Yasuri Test</title></head>
  <body>
    <p>Hello,Yasuri</p>
    <a href="./child01.html">child01</a>
    <a href="./child02.html">child02</a>
    <a href="./child03.html">child03</a>
  </body>
<title>
```

```html
<!-- http://yasuri.example.net/child01.html -->
<html>
  <head><title>Child 01 Test</title></head>
  <body>
    <p>Child 01 page.</p>
    <ul>
      <li><a href="./child01_sub.html">Child01_Sub</a></li>
      <li><a href="./child02_sub.html">Child02_Sub</a></li>
    </ul>
  </body>
<title>
```

```html
<!-- http://yasuri.example.net/child02.html -->
<html>
  <head><title>Child 02 Test</title></head>
  <body>
    <p>Child 02 page.</p>
  </body>
<title>
```

```html
<!-- http://yasuri.example.net/child03.html -->
<html>
  <head><title>Child 03 Test</title></head>
  <body>
    <p>Child 03 page.</p>
    <ul>
      <li><a href="./child03_sub.html">Child03_Sub</a></li>
    </ul>
  </body>
<title>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net")

node = Yasuri.links_title '/html/body/a' do
  text_content '/html/body/p'
end

node.inject(agent, page)
#=> [ {"content" => "Child 01 page."},
      {"content" => "Child 02 page."},
      {"content" => "Child 03 page."}]
```

At first, Links Node find all links in the page by path. In this case, LinksNode find `/html/body/a` tags in `http://yasuri.example.net`. Then, open href attributes (`./child01.html`, `./child02.html` and `./child03.html`).

Then, Links Node and apply child nodes. Links Node will return applied result of each page as array.

### Options
None.

## Paginate Node
Paginate Node parses and returns each pages that provid by paginate.

### Example
Target page `page01.html` is like this. `page02.html` to `page04.html` are similarly.

```html
<!-- http://yasuri.example.net/page01.html -->
<html>
  <head><title>Page01</title></head>
  <body>
    <p>Pagination01</p>

    <nav class='pagination'>
      <span class='prev'> PreviousPage </span>
      <span class='page'> 1 </span>
      <span class='page'> <a href="./page02.html">2</a> </span>
      <span class='page'> <a href="./page03.html">3</a> </span>
      <span class='page'> <a href="./page04.html">4</a> </span>
      <span class='next'> <a href="./page02.html" class="next" rel="next"> NextPage </a> </span>
    </nav>

  </body>
<title>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net/page01.html")

node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" do
         text_content '/html/body/p'
       end

node.inject(agent, page)
#=> [ {"content" => "Pagination01"},
      {"content" => "Pagination02"},
      {"content" => "Pagination03"},
      {"content" => "Pagination04"}]
```

Paginate Node require link for next page. In this case, it is `NextPage` `/html/body/nav/span/a[@class='next']`.

### Options
##### `limit`
Upper limit of open pages in pagination.

```ruby
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:2 do
         text_content '/html/body/p'
       end
node.inject(agent, page)
#=> [ {"content" => "Pagination01"}, {"content" => "Pagination02"}]
```
Paginate Node open upto 3 given by `limit`. In this situation, pagination has 4 pages, but result json has 2 texts because given `limit:2`.
