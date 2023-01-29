#!/usr/bin/env ruby

require 'base64'

# Generate base64 key/values for config:
# ./sixtify FOO=value
# => FOO: dmFsdWU=

args = ARGV

args.each do |arg|
  key, value = arg.split('=')
  encoded_value = value ? Base64.strict_encode64(value) : ''
  puts "#{key}: #{encoded_value}"
end
