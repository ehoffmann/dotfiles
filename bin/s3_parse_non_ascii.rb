#!/usr/bin/env ruby

require 'csv'
require 'cgi'

# Detect non-ascii string

def contains_non_ascii?(str)
  !str.ascii_only?
end

# https://cdn2.tzy2.li/teezily-plus/uploads/design/picture/4921689/TA4371_In_Flames_T%C3%8A.png

# URL decode
lines = File.readlines('teezily-plus.csv')
decoded_lines = lines.map do |line|
  CGI.unescape(line.chomp)
end

File.write('decoded_lines.txt', decoded_lines.join("\n"))

keys = []
File.open('decoded_lines.txt') do |file|
  file.each_line do |line|
    keys << line if contains_non_ascii?(line)
  end
end

File.write('keys.txt', keys.join)
