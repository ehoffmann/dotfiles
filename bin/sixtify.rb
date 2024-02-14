#!/usr/bin/env ruby

require 'base64'

# Generate base64 key/values for config:
# ./sixtify FOO=value
# => FOO: dmFsdWU=

args = ARGV

# Decode with -d
if args[0] == '-d'
  args.shift
  args.each do |arg|
    key, value = arg.split(':')
    value = value.strip
    decoded_value = value ? Base64.strict_decode64(value) : ''
    puts "#{key}=#{decoded_value}"
  end
  exit
end

args.each do |arg|
  key, value = arg.split('=')
  value = value.strip.gsub(/\A(['"])(.*?)\1\Z/, '\2')
  encoded_value = value ? Base64.strict_encode64(value) : ''
  puts "#{key}: #{encoded_value}"
end

