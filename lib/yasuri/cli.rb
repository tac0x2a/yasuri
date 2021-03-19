require "thor"

module YasuriUtils
  class CLI < Thor
    desc "sample", "sample script"
    def sample(str)
      puts "Hello, Yasuri. Hello, #{str}"
    end
  end
end