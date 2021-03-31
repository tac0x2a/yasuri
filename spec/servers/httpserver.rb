
require 'glint'

server = Glint::Server.new do |port|

  require 'webrick'
  http = WEBrick::HTTPServer.new({
    DocumentRoot: 'spec/htdocs',
    BindAddress:  '127.0.0.1',
    Port:         port,
    AccessLog: []
  })

  trap(:INT)  { http.shutdown }
  trap(:TERM) { http.shutdown }
  http.start
end

server.start

Glint::Server.info[:httpserver] = {
  host: "127.0.0.1",
  port: server.port
}
