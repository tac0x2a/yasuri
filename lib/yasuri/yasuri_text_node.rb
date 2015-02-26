
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class TextNode
    include Node
    def initialize(xpath, name, children = [], truncate: nil, opt: {})
      super(xpath, name, children)

      truncate_opt = opt["truncate"] #str
      truncate_opt = Regexp.new(truncate_opt) if not truncate_opt.nil? # regexp or nil

      @truncate = truncate || truncate_opt || nil # regexp or nil

      @truncate = Regexp.new(@truncate.to_s) if not @truncate.nil?

    end
    def inject(agent, page, retry_count = 5)
      node = page.search(@xpath)
      text = node.text.to_s

      text = text[@truncate, 0] if @truncate

      text.to_s
    end
    def opts
      {truncate:@truncate}
    end
  end
end
