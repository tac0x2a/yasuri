
# Author::    TAC (tac@tac42.net)

require_relative 'yasuri_node'

module Yasuri
  module Node
    attr_reader :url, :xpath, :name, :children

    def initialize(xpath, name, children = [], opt: {})
      @xpath, @name, @children = xpath, name, children
    end

    def inject(agent, page)
      fail "#{Kernel.__method__} is not implemented."
    end
    def opts
      {}
    end
  end
end
