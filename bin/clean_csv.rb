#!/usr/bin/env ruby
require 'csv'

# Use for T4B wallet support

# Usage
# cleancsv "test    123,234, test @gmail
# ...
# "
# => "test,123.234,test@gmail"
#
input_data = ARGV[0]

CSV.parse(input_data, col_sep: "\t") do |row|
  cleaned = row.map {|field| field.gsub(/ /, '').gsub(/,/, '.') }
  puts CSV.generate_line(cleaned, col_sep: ',')
end
