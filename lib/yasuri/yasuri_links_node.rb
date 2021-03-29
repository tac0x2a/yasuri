
require_relative 'yasuri_node'

module Yasuri
  class LinksNode
    include Node

    def inject(agent, page, opt = {}, element = page)
      retry_count = opt[:retry_count] || Yasuri::DefaultRetryCount
      interval_ms = opt[:interval_ms] || Yasuri::DefaultInterval_ms

      links = element.search(@xpath) || [] # links expected
      links.map do |link|
        link_button = Mechanize::Page::Link.new(link, agent, page)
        child_page = Yasuri.with_retry(retry_count, interval_ms) { link_button.click }

        child_results_kv = @children.map do |child_node|
          child_name = Yasuri.node_name(child_node.name, opt)
          [child_name, child_node.inject(agent, child_page, opt)]
        end

        Hash[child_results_kv]
      end
    end

    def node_type_str
      "links".freeze
    end
  end
end
