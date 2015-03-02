
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class TextNode
    include Node

    def initialize(xpath, name, children = [], truncate: nil)
      super(xpath, name, children)

      truncate = Regexp.new(truncate) if not truncate.nil? # regexp or nil

      @truncate = truncate
      @truncate = Regexp.new(@truncate.to_s) if not @truncate.nil?
    end

    def inject(agent, page, opt = {})
      node = page.search(@xpath)
      text = node.text.to_s

      if @truncate
        matches = @truncate.match(text)
        text = matches ? matches[1] || matches[0] || text : ""
      end

      text.to_s
    end
    def opts
      {truncate:@truncate}
    end
  end
end
