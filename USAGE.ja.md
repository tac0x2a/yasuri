# Yasuri の使い方

## Yasuri とは
Yasuri (鑢) は簡単にWebスクレイピングを行うための、"[Mechanize](https://github.com/sparklemotion/mechanize)" をサポートするライブラリです．

Yasuriは、スクレイピングにおける、よくある処理を簡単に記述することができます．
例えば、

+ ページ内の複数のリンクを開いて、各ページをスクレイピングした結果をHashで取得する
+ ページ内の複数のテキストをスクレイピングし、名前をつけてHashにする
+ ページ内に繰り返し出現するテーブルをそれぞれスクレイピングして、配列として取得する
+ ページネーションで提供される各ページのうち、上位3つだけを順にスクレイピングする

これらを簡単に実装することができます．

## クイックスタート

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
この例では、 LinkNode(`links_root`)の xpath で指定された各リンク先のページから、TextNode(`text_title`,`text_content`) の xpath で指定された2つのテキストをスクレイピングする例です．

(言い換えると、`//*[@id="menu"]/ul/li/a` で示される各リンクを開いて、`//*[@id="contents"]/h2` と `//*[@id="contents"]/p[1]` で指定されたテキストをスクレイピングします)

## 基本

1. パースツリーを作る
2. Mechanize の agent と対象のページを与えてパースを開始する


### パースツリーを作る

```ruby
require 'mechanize'
require 'yasuri'


# 1. パースツリーを作る
tree = Yasuri.links_title '/html/body/a' do
         text_name '/html/body/p'
       end

# 2. Mechanize の agent と対象のページを与えてパースを開始する
agent = Mechanize.new
page = agent.get(uri)


tree.inject(agent, page)
```

ツリーは、json，yaml，またはDSLで定義することができます．上の例ではDSLで定義しています．
以下は、jsonで上記と等価な解析ツリーを定義した例です．

```ruby
# json で構成する場合
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

```ruby
# yaml で構成する場合
src = <<-EOYAML
title:
  node: links
  path: "/html/body/a"
  children:
    - name:
        node: text
        path: "/html/body/p"
EOYAML
tree = Yasuri.yaml2tree(src)
```

### Node
ツリーは入れ子になった *Node* で構成されます．
Node は `Type`, `Name`, `Path`, `Childlen`, `Options` を持っています．
(ただし、`MapNode` のみ `Path` を持ちません)

Nodeは以下のフォーマットで定義されます．

```ruby
Yasuri.<Type>_<Name> <Path> [,<Options>]

# 入れ子になっている場合
Yasuri.<Type>_<Name> <Path> [,<Options>] do
  <Type>_<Name> <Path> [,<Options>] do
    <Type>_<Name> <Path> [,<Options>]
    ...
  end
end
```

例

```ruby
Yasuri.text_title '/html/head/title', truncate:/^[^,]+/

# 入れ子になっている場合
Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
  struct_table './tr' do
    text_title    './td[1]'
    text_pub_date './td[2]'
  end
end
```


#### Type
*Type* は Nodeの振る舞いを示します．Typeには以下のものがあります．

- *Text*
- *Struct*
- *Links*
- *Paginate*
- *Map*

#### Name
*Name* は 解析結果のHashにおけるキーになります．

#### Path
*Path* は xpath あるいは css セレクタによって、HTML上の特定のノードを指定します．
これは Machinize の `search` で使用されます．

#### Childlen
入れ子になっているノードの子ノードです．TextNodeはツリーの葉に当たるため、子ノードを持ちません．

#### Options
パースのオプションです．オプションはTypeごとに異なります．
各ノードに対して、`opt`メソッドをコールすることで、利用可能なオプションを取得できます．

```
# TextNode の例
node = Yasuri.text_title '/html/body/p[1]', truncate:/^[^,]+/
node.opt #=> {:truncate => /^[^,]+/, :proc => nil}
```

## Text Node
*TextNode* はスクレイピングしたテキストを返します．このノードはパースツリーにおいて常に葉です．

### 例

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
p2u = Yasuri.text_title '/html/body/p[1]', proc: :upcase

p1.inject(agent, page)   #=> "Hello,World"
p1t.inject(agent, page)  #=> "Hello"
p2u.inject(agent, page)  #=> "HELLO,WORLD"
```

なお、同じページ内の複数の要素を一度にスクレイピングする場合は、`MapNode`を使用します。

### オプション
##### `truncate`
正規表現にマッチした文字列を取り出します．グループを指定した場合、最初にマッチしたグループだけを返します．

```ruby
node  = Yasuri.text_example '/html/body/p[1]', truncate:/H(.+)i/
node.inject(agent, index_page)
#=> { "example" => "ello,Yasur" }
```


##### `proc`
取り出した文字列(String)をレシーバーとして、シンボルで指定したメソッドを呼び出します．
`truncate`オプションを併せて指定している場合、`truncate`した後の文字列に対し、メソッドを呼び出します．

```ruby
node = Yasuri.text_example '/html/body/p[1]', proc: :upcase, truncate:/H(.+)i/
node.inject(agent, index_page)
#=> { "example" => "ELLO,YASUR" }
```

## Struct Node
*Struct Node*  は構造化されたHashとしてテキストを返します．

まず、Struct Node は `Path` によって、HTMLのタグを絞込みます．
Struct Node の子ノードは、この絞りこまれたタグに対してパースを行い、Struct Node は子ノードの結果を含むHashを返します．

Struct Node の `Path` が複数のタグにマッチする場合、配列として結果を返します．

### 例

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

Struct Node は xpath `'/html/body/table[1]/tr'` によって、最初の `<table>` から すべての`<tr>` タグを絞り込みます．
その後、子ノードである2つの TextNode によって、 `<tr>` タグがパースされます．
この場合は、最初の `<table>` は 3つの `<tr>`タグを持っているため、3つのHashを返します．(`<thead><tr>` は `Path` にマッチしないため4つではないことに注意)
各HashはTextNodeによってパースされたテキストを含んでいます．


また以下の例のように、Struct Node は TextNode以外のノードを子ノードとすることができます．

### 例

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

### オプション
なし

## Links Node
Links Node は リンクされた各ページをパースして結果を返します．

### 例
```
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

```
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

```
<!-- http://yasuri.example.net/child02.html -->
<html>
  <head><title>Child 02 Test</title></head>
  <body>
    <p>Child 02 page.</p>
  </body>
<title>
```

```
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

```
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

まず、 LinksNode は `Path` にマッチするすべてのリンクを最初のページから探します．
この例では、LinksNodeは `/html/body/a` にマッチするすべてのタグを `http://yasuri.example.net` から探します．
次に、見つかったタグのhref属性で指定されたページを開きます．(`./child01.html`, `./child02.html`, `./child03.html`)

開いた各ページに対して、子ノードによる解析を行います．LinksNodeは 各ページに対するパース結果をHashの配列として返します．

## Paginate Node
PaginateNodeは ページネーション(パジネーション, Pagination) でたどることのできる各ページを順にパースします．

### 例
この例では、対象のページ `page01.html` はこのようになっているとします．
`page02.html` から `page04.html` も同様です．

```html
<!-- http://yasuri.example.net/page01.html -->
<html>
  <head><title>Page01</title></head>
  <body>
    <p>Patination01</p>

    <nav class='pagination'>
      <span class='prev'> &laquo; PreviousPage </span>
      <span class='page'> 1 </span>
      <span class='page'> <a href="./page02.html">2</a> </span>
      <span class='page'> <a href="./page03.html">3</a> </span>
      <span class='page'> <a href="./page04.html">4</a> </span>
      <span class='next'> <a href="./page02.html" class="next" rel="next">NextPage &raquo;</a> </span>
    </nav>

  </body>
<title>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net/page01.html")

node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:3 do
         text_content '/html/body/p'
       end

node.inject(agent, page)
#=> [ {"content" => "Patination01"},
      {"content" => "Patination02"},
      {"content" => "Patination03"}]
```
PaginateNodeは 次のページ を指すリンクを`Path`として指定する必要があります．
この例では、`NextPage` (`/html/body/nav/span/a[@class='next']`)が、次のページを指すリンクに該当します．

### オプション
##### `limit`
たどるページ数の上限を指定します．

```ruby
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:2 do
         text_content '/html/body/p'
       end
node.inject(agent, page)
#=> [ {"content" => "Pagination01"}, {"content" => "Pagination02"}]
```
この場合、PaginateNode は最大2つまでのページを開いてパースします．ページネーションは4つのページを持っているようですが、`limit:2`が指定されているため、結果の配列には2つの結果のみが含まれています．

##### `flatten`
取得した各ページの結果を展開します．

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net/page01.html")

node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , flatten:true do
         text_title   '/html/head/title'
         text_content '/html/body/p'
       end
node.inject(agent, page)

#=> [ {"title" => "Page01",
       "content" => "Patination01"},
      {"title"   => "Page01",
       "content" => "Patination02"},
      {"title"   => "Page01",
       "content" => "Patination03"}]


node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , flatten:true do
        text_title   '/html/head/title'
        text_content '/html/body/p'
      end
node.inject(agent, page)

#=> [ "Page01",
      "Patination01",
      "Page02",
      "Patination02",
      "Page03",
      "Patination03"]
```

## Map Node
*MapNode* はスクレイピングした結果をまとめるノードです．このノードはパースツリーにおいて常に節です．

### 例

```html
<!-- http://yasuri.example.net -->
<html>
  <head><title>Yasuri Example</title></head>
  <body>
    <p>Hello,World</p>
    <p>Hello,Yasuri</p>
  </body>
</html>
```

```ruby
agent = Mechanize.new
page = agent.get("http://yasuri.example.net")


tree = Yasuri.map_root do
  text_title  '/html/head/title'
  text_body_p '/html/body/p[1]'
end

tree.inject(agent, page) #=> { "title" => "Yasuri Example", "body_p" => "Hello,World" }


tree = Yasuri.map_root do
  map_group1 { text_child01  '/html/body/a[1]' }
  map_group2 do
    text_child01 '/html/body/a[1]'
    text_child03 '/html/body/a[3]'
  end
end

tree.inject(agent, page) #=> {
#   "group1" => {
#           "child01" => "child01"
#         },
#         "group2" => {
#           "child01" => "child01",
#           "child03" => "child03"
#         }
# }
```

### オプション
なし
