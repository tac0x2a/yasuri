
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  class TextNode
    include Node

    def initialize(xpath, name, children = [], hash = {})
      super(xpath, name, children)

      truncate = hash[:truncate]
      proc     = hash[:proc]

      truncate = Regexp.new(truncate) if not truncate.nil? # regexp or nil
      @truncate = truncate
      @truncate = Regexp.new(@truncate.to_s) if not @truncate.nil?

      @proc = proc.nil? ? nil : proc.to_sym

    end

    def inject(agent, page, opt = {}, element = page)
      node = element.search(@xpath)
      text = node.text.to_s

      if @truncate
        matches = @truncate.match(text)
        text = matches ? matches[1] || matches[0] || text : ""
      end

      text = text.__send__(@proc) if @proc && text.respond_to?(@proc)
      text
    end

    def opts
      {truncate:@truncate, proc:@proc}
    end
  end
end
