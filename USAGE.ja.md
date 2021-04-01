# Yasuri

## Yasuri とは
Yasuri (鑢) はWebスクレイピングを宣言的に行うためのライブラリと、それを用いたスクレイピングのコマンドラインツールです。

簡単な宣言的記法で期待結果を記述するだけでスクレイピングした結果を得られます。

Yasuriは、スクレイピングにおける、よくある処理を簡単に記述することができます．
例えば、以下のような処理を簡単に実現することができます．

+ ページ内の複数のテキストをスクレイピングし、名前をつけてHashにする
+ ページ内の複数のリンクを開いて、各ページをスクレイピングした結果をHashで取得する
+ ページ内に繰り返し出現するテーブルをそれぞれスクレイピングして、配列として取得する
+ ページネーションで提供される各ページのうち、最初の3ページだけをスクレイピングする

## クイックスタート

#### インストール
```sh
# for Ruby 2.3.2
$ gem 'yasuri', '~> 2.0', '>= 2.0.13'
```
または
```sh
# for Ruby 3.0.0 or upper
$ gem install yasuri
```

#### ライブラリとして使う
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

この例では、 LinkNode(`links_root`)の xpath で指定された各リンク先のページから、TextNode(`text_title`,`text_content`) の xpath で指定された2つのテキストをスクレイピングする例です．

(言い換えると、`//*[@id="menu"]/ul/li/a` で示される各リンクを開いて、`//*[@id="contents"]/h2` と `//*[@id="contents"]/p[1]` で指定されたテキストをスクレイピングします)


#### CLIツールとして使う
上記と同じことを、CLIのコマンドとして実行できます。

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

Dockerでも実行できます。

```sh
$ docker build . -t yasuri
$ docker run yasuri yasuri scrape "https://www.ruby-lang.org/en/" -j '
{
  "text_title": "/html/head/title",
  "text_desc": "//*[@id=\"intro\"]/p"
}'

{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}
```

結果はjson形式の文字列として取得できます。

----------------------------
## パースツリー

パースツリーとは、スクレイピングする要素と出力構造を宣言的に定義するための木構造データです。
パースツリーは入れ子になった Node で構成されます．Node は `Type`, `Name`, `Path`, `Childlen`, `Options` 属性を持っており、その `Type` に応じたスクレイピング処理を行います．(ただし、`MapNode` のみ `Path` を持ちません)


パースツリーは以下のフォーマットで定義されます．

```ruby
# 1ノードからなる単純なツリー
Yasuri.<Type>_<Name> <Path> [,<Options>]

# 入れ子になっているツリー
Yasuri.<Type>_<Name> <Path> [,<Options>] do
  <Type>_<Name> <Path> [,<Options>] do
    <Type>_<Name> <Path> [,<Options>]
    ...
  end
end
```

**例**

```ruby
# 1ノードからなる単純なツリー
Yasuri.text_title '/html/head/title', truncate:/^[^,]+/

# 入れ子になっているツリー
Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
  struct_table './tr' do
    text_title    './td[1]'
    text_pub_date './td[2]'
  end
end
```


パースツリーはRubyのDSL、JSON、YAMLのいずれかで定義することができます。
以下は、上記と同じパースツリーをそれぞれの記法で定義した例です。

**Ruby DSLで定義する場合**
```ruby
Yasuri.links_title '/html/body/a' do
  text_name '/html/body/p'
end
```

**JSONで定義する場合**
```json
{
  links_title": {
    "path": "/html/body/a",
    "text_name": "/html/body/p"
  }
}
```

**YAMLで定義する場合**
```yaml
links_title:
  path: "/html/body/a"
  text_name: "/html/body/p"
```

**パースツリーの特殊なケース**

rootの直下の要素が1つだけの場合、Hash(Object)ではなく、その要素を直接返します。
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


jsonまたはyaml形式では、子Nodeを持たない場合、`path` を直接値に指定することができます。以下の2つのjsonは同じパースツリーになります。

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
### ツリーを実行する
パースツリーのルートノードで`Node#scrape(uri, opt={})`メソッドをコールします。

**例**
```ruby
root = Yasuri.links_root '//*[@id="menu"]/ul/li/a' do
         text_title '//*[@id="contents"]/h2'
         text_content '//*[@id="contents"]/p[1]'
       end

result = root.scrape("http://some.scraping.page.tac42.net/", interval_ms: 1000)
```

+ `uri` はスクレイピングする対象ページのURIです。
+ `opt` はオプションをHashで指定します。以下のオプションを利用できます。

Yasuriはスクレイピングを行うエージェントとして、内部で`Mechanize`を使用しています。
このインスタンスを指定したい場合は、`Node#scrape_with_agent(uri, agent, opt={})`をコールします。

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
複数ページにリクエストする際の間隔[ミリ秒]です。

省略した場合はインターバルなしで続けてリクエストしますが、多数のページへのリクエストが予想される場合、対象ホストが高負荷とならないよう、インターバル時間を指定することを強くお勧めします。

#### `retry_count`
ページ取得失敗時のリトライ回数です。省略した場合は5回リトライします。

#### `symbolize_names`
`true`のとき、結果セットのキーをシンボルとして返します。

--------------------------
## Node

Nodeはパースツリーの節または葉となる要素で、`Type`, `Name`, `Path`, `Childlen`, `Options` を持っており、その `Type` に応じてスクレイピングを行います．(ただし、`MapNode` のみ `Path` を持ちません)


#### Type
*Type* は Nodeの振る舞いを示します．Typeには以下のものがあります．

- *Text*
- *Struct*
- *Links*
- *Paginate*
- *Map*

詳細は各ノードの説明を参照してください。

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

なお、同じページ内の複数の要素を一度にスクレイピングする場合は、`MapNode`を使用します。詳細は、`MapNode`の例を参照してください。

### オプション
##### `truncate`
正規表現にマッチした文字列を取り出します．グループを指定した場合、最初にマッチしたグループだけを返します．

```ruby
node  = Yasuri.text_example '/html/body/p[1]', truncate:/H(.+)i/
node.scrape(uri)
#=> { "example" => "ello,Yasur" }
```


##### `proc`
取り出した文字列(String)をレシーバーとして、シンボルで指定したメソッドを呼び出します．
`truncate`オプションを併せて指定している場合、`truncate`した後の文字列に対し、メソッドを呼び出します．

```ruby
node = Yasuri.text_example '/html/body/p[1]', proc: :upcase, truncate:/H(.+)i/
node.scrape(uri)
#=> { "example" => "ELLO,YASUR" }
```

## Struct Node
*Struct Node*  は構造化されたHashとしてテキストを返します．

まず、Struct Node は `Path` によって、HTMLのタグを絞込みます．
Struct Node の子ノードは、この絞りこまれたタグに対してパースを行い、Struct Node は子ノードの結果を含むHashを返します．

Struct Node の `Path` が複数のタグにマッチする場合、配列として結果を返します．

### 例

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

Struct Node は xpath `'/html/body/table[1]/tr'` によって、最初の `<table>` から すべての`<tr>` タグを絞り込みます．
その後、子ノードである2つの TextNode によって、 `<tr>` タグがパースされます．
この場合は、最初の `<table>` は 3つの `<tr>`タグを持っているため、3つのHashを返します．(`<thead><tr>` は `Path` にマッチしないため4つではないことに注意)
各HashはTextNodeによってパースされたテキストを含んでいます．

また以下の例のように、Struct Node は TextNode以外のノードを子ノードとすることができます．

### 例

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

### オプション
なし

## Links Node
Links Node は リンクされた各ページをパースして結果を返します．

### 例
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

まず、 LinksNode は `Path` にマッチするすべてのリンクを最初のページから探します．
この例では、LinksNodeは `/html/body/a` にマッチするすべてのタグを `http://yasuri.example.tac42.net` から探します．
次に、見つかったタグのhref属性で指定されたページを開きます．(`./child01.html`, `./child02.html`, `./child03.html`)

開いた各ページに対して、子ノードによる解析を行います．LinksNodeは 各ページに対するパース結果をHashの配列として返します．

## Paginate Node
PaginateNodeは ページネーション(パジネーション, Pagination) でたどることのできる各ページを順にパースします．

### 例
この例では、対象のページ `page01.html` はこのようになっているとします．
`page02.html` から `page04.html` も同様です．

```html
<!-- http://yasuri.example.tac42.net/page01.html -->
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
node = Yasuri.pages_root "/html/body/nav/span/a[@class='next']" , limit:3 do
         text_content '/html/body/p'
       end

node.scrape("http://yasuri.example.tac42.net/page01.html")
#=> [ {"content" => "Patination01"},
#     {"content" => "Patination02"},
#     {"content" => "Patination03"}]
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
node.scrape(uri)
#=> [ {"content" => "Pagination01"}, {"content" => "Pagination02"}]
```
この場合、PaginateNode は最大2つまでのページを開いてパースします．ページネーションは4つのページを持っているようですが、`limit:2`が指定されているため、結果の配列には2つの結果のみが含まれています．

##### `flatten`
取得した各ページの結果を展開します．

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
*MapNode* はスクレイピングした結果をまとめるノードです．このノードはパースツリーにおいて常に節です．

### 例

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

### オプション
なし


-------------------------
## 使い方

### ライブラリとして使う
ライブラリとして使用する場合は、DSL, json, yaml の形式でツリーを定義できます。

```ruby
require 'yasuri'

# 1. パースツリーを作る
# DSLで定義する
tree = Yasuri.links_title '/html/body/a' do
         text_name '/html/body/p'
       end

# jsonで定義する場合
src = <<-EOJSON
{
  links_title": {
    "path": "/html/body/a",
    "text_name": "/html/body/p"
  }
}
EOJSON
tree = Yasuri.json2tree(src)


# yamlで定義する場合
src = <<-EOYAML
links_title:
  path: "/html/body/a"
  text_name: "/html/body/p"
EOYAML
tree = Yasuri.yaml2tree(src)

# 2. URLを与えてパースを開始する
tree.inject(uri)
```

### CLIツールとして使う

**ヘルプ表示**
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

CLIツールでは以下のどちらかの方法でパースツリーを指定します。
+ `--file`, `-f` : ファイルに出力されたjson形式またはyaml形式のパースツリーを読み込む
+ `--json`, `-j` : パースツリーを文字列として直接指定する


**パースツリーをファイルで指定する例**
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

ファイルがjsonまたはyamlのどちらで記載されているかについては自動判別されます。

**パースツリーをjsonで直接指定する例**
```sh
$ yasuri scrape "https://www.ruby-lang.org/en/" -j '
{
  "text_title": "/html/head/title",
  "text_desc": "//*[@id=\"intro\"]/p"
}'

{"title":"Ruby Programming Language","desc":"\n    A dynamic, open source programming language with a focus on\n    simplicity and productivity. It has an elegant syntax that is\n    natural to read and easy to write.\n    "}
```

#### その他のオプション
+ `--interval`, `-i` : 複数ページにリクエストする際の間隔[ミリ秒]です。
   **例: 1秒間隔でリクエストする**
   ```sh
   $ yasuri scrape "https://www.ruby-lang.org/en/" --file sample.yml --interval 1000
   ```
