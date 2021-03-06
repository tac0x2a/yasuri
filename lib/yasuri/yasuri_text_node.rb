
require_relative 'yasuri_node'

module Yasuri
  class TextNode
    include Node

    def initialize(xpath, name, children = [], **opt)
      super(xpath, name, children)

      truncate = opt[:truncate]
      proc = opt[:proc]

      truncate = Regexp.new(truncate) unless truncate.nil? # regexp or nil
      @truncate = truncate
      @truncate = Regexp.new(@truncate.to_s) unless @truncate.nil?

      @proc = proc.nil? ? nil : proc.to_sym
    end

    def inject(_agent, page, _opt = {}, element = page)
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
      { truncate: @truncate, proc: @proc }
    end

    def node_type_str
      "text".freeze
    end
  end
end
