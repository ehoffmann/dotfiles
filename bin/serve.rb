#!/usr/bin/env ruby

require 'socket'
require 'redcarpet'

# Local .md HTTP server

server = TCPServer.new 2000

# files = `ls ~/work/@daily/*.md`.split
renderer = Redcarpet::Render::HTML.new
parser = Redcarpet::Markdown.new(renderer, autolink: true, tables: true, fenced_code_blocks: true)

css = File.read("/home/manu/work/retro.css")

def render_summary(client)
    # files = `ls ~/work/@daily/*.md`.split
    # data = File.read('/home/manu/work/recipes/cors.md')
    data = File.read(File.join(home, document))
    client.puts parser.render data
end

def render_200(client)
  client.puts "HTTP/1.1 200 OK"
  client.puts "Content-Type: text/html"
  client.puts "\n"
  client.puts "<head>"
  client.puts '<link href="/retro.css" rel="stylesheet">'
  client.puts '<meta charset="UTF-8">'
  client.puts "</head>"
end

loop do
  Thread.start(server.accept) do |client|
    request = client.gets
    puts request
    document = request.split[1]
    if request.include? 'GET /favicon.ico HTTP/1.1'
      client.puts "HTTP/1.1 404 Not Found"
      client.puts "\n"
      client.close
      next
    end

    if request.include? 'retro.css HTTP/1.1'
      client.puts "HTTP/1.1 200 OK"
      client.puts "Content-Type: text/css"
      client.puts "\n"
      client.puts css
      client.close
      next
    end

    if request.include? 'GET / HTTP/1.1'
      render_200(client)
      client.puts "<ul>"
      `ls ~/work/recipes/*.md`.split.each do |path|
        file = path.split('/').last
        client.puts "<li><a href='/recipes/#{file}'>#{file}</a></li>"
      end
      client.puts "</ul>"
      client.close
      next
    end

    render_200(client)
    home = '/home/manu/work'

    data = File.read(File.join(home, document))
    client.puts parser.render data
    client.close
  end
end
