# Yasuri

## What is Yasuri
`Yasuri` (鑢) is a library for declarative web scraping and a command line tool for scraping with it.

It performs scraping by simply describing the expected result in a simple declarative notation.

Yasuri makes it easy to write common scraping operations.
For example, the following processes can be easily implemented.

+ Scrape multiple texts in a page and name them into a Hash
+ Open multiple links in a page and get the result of scraping each page as a Hash
+ Scrape each table that appears repeatedly in the page and get the result as an array
+ Scrape only the first three pages of each page provided by pagination

## Quick Start


#### Install
```sh
# for Ruby 2.3.2
$ gem 'yasuri', '~> 2.0', '>= 2.0.13'
```
または
```sh
# for Ruby 3.0.0 or upper
$ gem install yasuri
```
#### Use as library
```ruby
require 'yasuri'
require 'machinize'

# Node tree constructing by DSL
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end

result = root.scrape("http://some.scraping.page.tac42.net/")
# => [
#      {"title" => "PageTitle 01", "content" => "Page Contents  01" },
#      {"title" => "PageTitle 02", "content" => "Page Contents  02" },
#      ...
#      {"title" => "PageTitle N",  "content" => "Page Contents  N" }
#    ]
```

This example, from the pages of each link that is expressed by the xpath of LinkNode(`links_root`), to scraping the two text that is expressed by the xpath of TextNode(`text_title`,`text_content`).

(in other words, open each links `//*[@id="menu"]/ul/li/a` and, scrape `//*[@id="contents"]/h2` and `//*[@id="contents"]/p[1]`.)


#### Use as CLI tool
The same thing as above can be executed as a CLI command.

```sh
$ yasuri scrape "http://some.scraping.page.tac42.net/" -j '
{
  "links_root": {
    "path": "//*[@id=\"menu\"]/ul/li/a",
    "text_title": "//*[@id=\"contents\"]/h2",
    "text_content": "//*[@id=\"contents\"]/p[1]"
    }
}'

[
  {"title":"PageTitle 01","content":"Page Contents  01"},
  {"title":"PageTitle 02","content":"Page Contents  02"},
  ...,
  {"title":"PageTitle N","content":"Page Contents  N"}
]
```

Also can be run on Docker

```sh
$ docker build . -t yasuri
$ docker run yasuri yasuri scrape "https://www.ruby-lang.org/en/" -j '
{
  "text_title": "/html/head/title",
  "text_desc": "//*[@id=\"intro\"]/p"
}'

{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}
```


The result can be obtained as a string in json format.

----------------------------
## Parse Tree

A parse tree is a tree structure data for declaratively defining the elements to be scraped and the output structure.

A parse tree consists of nested `Node`s, each of which has `Type`, `Name`, `Path`, `Childlen`, and `Options` attributes, and scrapes according to its `Type`. (Note that only `MapNode` does not have `Path`).

The parse tree is defined in the following format:

```ruby
# A simple tree consisting of one node
Yasuri.<Type>_<Name> <Path> [,<Options>]

# Nested tree
Yasuri.<Type>_<Name> <Path> [,<Options>] do
  <Type>_<Name> <Path> [,<Options>] do
    <Type>_<Name> <Path> [,<Options>]
    ...
  end
end
```

**Example**

```ruby
# A simple tree consisting of one node
Yasuri.text_title '/html/head/title', truncate:/^[^,]+/

# Nested tree
Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
  struct_table './tr' do
    text_title    './td[1]'
    text_pub_date './td[2]'
  end
end
```

Parsing trees can be defined in Ruby DSL, JSON, or YAML.
The following is an example of the same parse tree as above, defined in each notation.


**Case of defining as Ruby DSL**
```ruby
Yasuri.links_title '/html/body/a' do
  text_name '/html/body/p'
end
```

**Case of defining as JSON**
```json
{
  links_title": {
    "path": "/html/body/a",
    "text_name": "/html/body/p"
  }
}
```

**Case of defining as YAML**
```yaml
links_title:
  path: "/html/body/a"
  text_name: "/html/body/p"
```

**Special case of purse tree**

If there is only one element directly under the root, it will return that element directly instead of Hash(Object).
```json
{
  "text_title": "/html/head/title",
  "text_body": "/html/body",
}
# => {"title": "Welcome to yasuri!", "body": "Yasuri is ..."}

{
  "text_title": "/html/head/title"}
}
# => Welcome to yasuri!
```


In json or yaml format, a attribute can directly specify `path` as a value if it doesn't have any child Node. The following two json will have the same parse tree.

```json
{
  "text_name": "/html/body/p"
}

{
  "text_name": {
    "path": "/html/body/p"
  }
}
```
### Run ParseTree
Call the `Node#scrape(uri, opt={})` method on the root node of the parse tree.

**Example**
```ruby
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end

result = root.scrape("http://some.scraping.page.tac42.net/", interval_ms: 1000)
```

+ `uri` is the URI of the page to be scraped.
+ `opt` is options as Hash. The following options are available.

Yasuri uses `Mechanize` internally as an agent to do scraping.
If you want to specify this instance, call `Node#scrape_with_agent(uri, agent, opt={})`.

```ruby
require 'logger'

agent = Mechanize.new
agent.log = Logger.new $stderr
agent.request_headers = {
  # ...
}

result = root.scrape_with_agent(
  "http://some.scraping.page.tac42.net/",
  agent,
  interval_ms: 1000)
```

### `opt`
#### `interval_ms`
Interval [milliseconds] for requesting multiple pages.

If omitted, requests will be made continuously without an interval, but if requests to many pages are expected, it is strongly recommended to specify an interval time to avoid high load on the target host.

#### `retry_count`
Number of retries when page acquisition fails. If omitted, it will retry 5 times.

#### `symbolize_names`
If true, returns the keys of the result set as symbols.

--------------------------
## Node

Node is a node or leaf of the parse tree, which has `Type`, `Name`, `Path`, `Childlen`, and `Options`, and scrapes according to its `Type`. (Note that only `MapNode` does not have `Path`).


#### Type
Type meen behavior of Node.

- *Text*
- *Struct*
- *Links*
- *Paginate*
- *Map*

See the description of each node for details.

#### Name
Name is used keys in returned hash.

#### Path
Path determine target node by xpath or css selector. It given by Machinize `search`.

#### Childlen
Child nodes. TextNode has always empty set, because TextNode is leaf.

#### Options
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
<!-- http://yasuri.example.tac42.net -->
<html>
  <head></head>
  <body>
    <p>Hello,World</p>
    <p>Hello,Yasuri</p>
  </body>
</html>
```

```ruby
p1  = Yasuri.text_title '/html/body/p[1]'
p1t = Yasuri.text_title '/html/body/p[1]', truncate:/^[^,]+/
p2u = Yasuri.text_title '/html/body/p[1]', proc: :upcase

p1.scrape("http://yasuri.example.tac42.net")   #=> "Hello,World"
p1t.scrape("http://yasuri.example.tac42.net")  #=> "Hello"
p2u.scrape("http://yasuri.example.tac42.net")  #=> "HELLO,WORLD"
```

Note that if you want to scrape multiple elements in the same page at once, use `MapNode`. See the `MapNode` example for details.

### Options
##### `truncate`
Match to regexp, and truncate text. When you use group, it will return first matched group only.

```ruby
node  = Yasuri.text_example '/html/body/p[1]', truncate:/H(.+)i/
node.scrape(uri)
#=> { "example" => "ello,Yasur" }
```


##### `proc`
Apply method to text. Method is given as Symbol.
If it is given `truncate` option, apply method after truncated.

```ruby
node = Yasuri.text_example '/html/body/p[1]', proc: :upcase, truncate:/H(.+)i/
node.scrape(uri)
#=> { "example" => "ELLO,YASUR" }
```

## Struct Node
Struct Node return structured text.

At first, Struct Node narrow down sub-tags by `Path`.
Child nodes parse narrowed tags, and struct node returns hash contains parsed result.

If Struct Node `Path` matches multi sub-tags, child nodes parse each sub-tags and struct node returns array.

### Example

```html
<!-- http://yasuri.example.tac42.net -->
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
node = Yasuri.struct_table '/html/body/table[1]/tr' do
  text_title    './td[1]'
  text_pub_date './td[2]'
end

node.scrape("http://yasuri.example.tac42.net")
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
node = Yasuri.strucre_tables '/html/body/table' do
  struct_table './tr' do
    text_title    './td[1]'
    text_pub_date './td[2]'
  end
end

node.scrape("http://yasuri.example.tac42.net")

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
<!-- http://yasuri.example.tac42.net -->
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
<!-- http://yasuri.example.tac42.net/child01.html -->
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
<!-- http://yasuri.example.tac42.net/child02.html -->
<html>
  <head><title>Child 02 Test</title></head>
  <body>
    <p>Child 02 page.</p>
  </body>
<title>
```

```html
<!-- http://yasuri.example.tac42.net/child03.html -->
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
node = Yasuri.links_title '/html/body/a' do
  text_content '/html/body/p'
end

node.scrape("http://yasuri.example.tac42.net")
#=> [ {"content" => "Child 01 page."},
      {"content" => "Child 02 page."},
      {"content" => "Child 03 page."}]
```

At first, Links Node find all links in the page by path. In this case, LinksNode find `/html/body/a` tags in `http://yasuri.example.tac42.net`. Then, open href attributes (`./child01.html`, `./child02.html` and `./child03.html`).

Then, Links Node and apply child nodes. Links Node will return applied result of each page as array.

### Options
None.

## Paginate Node
Paginate Node parses and returns each pages that provid by paginate.

### Example
Target page `page01.html` is like this. `page02.html` to `page04.html` are similarly.

```html
<!-- http://yasuri.example.tac42.net/page01.html -->
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
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:3 do
         text_content '/html/body/p'
       end

node.scrape("http://yasuri.example.tac42.net/page01.html")
#=> [ {"content" => "Patination01"},
#     {"content" => "Patination02"},
#     {"content" => "Patination03"}]
```
Paginate Node require link for next page.
In this case, it is `NextPage` `/html/body/nav/span/a[@class='next']`.

### Options
##### `limit`
Upper limit of open pages in pagination.

```ruby
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:2 do
         text_content '/html/body/p'
       end
node.scrape(uri)
#=> [ {"content" => "Pagination01"}, {"content" => "Pagination02"}]
```
Paginate Node open upto 2 given by `limit`. In this situation, pagination has 4 pages, but result Array has 2 texts because given `limit:2`.

##### `flatten`
`flatten` option expands each page results.

```ruby
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , flatten:true do
         text_title   '/html/head/title'
         text_content '/html/body/p'
       end
node.scrape("http://yasuri.example.tac42.net/page01.html")

#=> [ {"title" => "Page01",
#      "content" => "Patination01"},
#     {"title"   => "Page01",
#      "content" => "Patination02"},
#     {"title"   => "Page01",
#      "content" => "Patination03"}]


node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , flatten:true do
        text_title   '/html/head/title'
        text_content '/html/body/p'
      end
node.scrape("http://yasuri.example.tac42.net/page01.html")

#=> [ "Page01",
#     "Patination01",
#     "Page02",
#     "Patination02",
#     "Page03",
#     "Patination03"]
```

## Map Node
*MapNode* is a node that summarizes the results of scraping. This node is always a branch node in the parse tree.

### Example

```html
<!-- http://yasuri.example.tac42.net -->
<html>
  <head><title>Yasuri Example</title></head>
  <body>
    <p>Hello,World</p>
    <p>Hello,Yasuri</p>
  </body>
</html>
```

```ruby
tree = Yasuri.map_root do
  text_title  '/html/head/title'
  text_body_p '/html/body/p[1]'
end

tree.scrape("http://yasuri.example.tac42.net") #=> { "title" => "Yasuri Example", "body_p" => "Hello,World" }


tree = Yasuri.map_root do
  map_group1 { text_child01  '/html/body/a[1]' }
  map_group2 do
    text_child01 '/html/body/a[1]'
    text_child03 '/html/body/a[3]'
  end
end

tree.scrape("http://yasuri.example.tac42.net") #=> {
#   "group1" => {
#           "child01" => "child01"
#         },
#         "group2" => {
#           "child01" => "child01",
#           "child03" => "child03"
#         }
# }
```

### Options
None.


-------------------------
## Usage

### Use as library
When used as a library, the tree can be defined in DSL, json, or yaml format.

```ruby
require 'yasuri'

# 1. Create a parse tree.
# Define by Ruby's DSL
tree = Yasuri.links_title '/html/body/a' do
         text_name '/html/body/p'
       end

# Define by JSON
src = <<-EOJSON
{
  links_title": {
    "path": "/html/body/a",
    "text_name": "/html/body/p"
  }
}
EOJSON
tree = Yasuri.json2tree(src)


# Define by YAML
src = <<-EOYAML
links_title:
  path: "/html/body/a"
  text_name: "/html/body/p"
EOYAML
tree = Yasuri.yaml2tree(src)

# 2. Give the URL to start parsing
tree.inject(uri)
```

### Use as CLI tool

**Help**
```sh
$ yasuri help scrape
Usage:
  yasuri scrape <URI> [[--file <TREE_FILE>] or [--json <JSON>]]

Options:
  f, [--file=FILE]  # path to file that written yasuri tree as json or yaml
  j, [--json=JSON]  # yasuri tree format json string
  i, [--interval=N]  # interval each request [ms]

Getting from <URI> and scrape it. with <JSON> or json/yml from <TREE_FILE>. They should be Yasuri's format json or yaml string.
```

In the CLI tool, you can specify the parse tree in either of the following ways.
+ `--file`, `-f` : option to read the parse tree in json or yaml format output to a file.
+ `--json`, `-j` : option to specify the parse tree directly as a string.


**Example of specifying a parse tree as a file**
```sh
% cat sample.yml
text_title: "/html/head/title"
text_desc: "//*[@id=\"intro\"]/p"

% yasuri scrape "https://www.ruby-lang.org/en/" --file sample.yml
{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}

% cat sample.json
{
  "text_title": "/html/head/title",
  "text_desc": "//*[@id=\"intro\"]/p"
}

% yasuri scrape "https://www.ruby-lang.org/en/" --file sample.json
{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}
```

Whether the file is written in json or yaml will be determined automatically.

**Example of specifying a parse tree directly in json**
```sh
$ yasuri scrape "https://www.ruby-lang.org/en/" -j '
{
  "text_title": "/html/head/title",
  "text_desc": "//*[@id=\"intro\"]/p"
}'

{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}
```

#### Other options
+ `--interval`, `-i` : The interval [milliseconds] for requesting multiple pages.
   **Example: Request at 1 second intervals**
   ```sh
   $ yasuri scrape "https://www.ruby-lang.org/en/" --file sample.yml --interval 1000
   ```
