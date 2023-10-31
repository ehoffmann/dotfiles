#!/usr/bin/env ruby

class Parser
  # Transform:
  # * Bump nokogiri from 1.14.3 to 1.14.4 [#2656][]
  # * Bump processout from 2.23.0 to 2.24.0 [#2658][]
  #
  # Into:
  # [#2656]: https://github.com/teezily/t4b/pull/2656
  # [#2658]: https://github.com/teezily/t4b/pull/2658
  #
  # Usage:
  # changelog "...[#2345]"
  def generate_link(input)
    url = []
    input.scan(/\[#(\d+)\]\[\]/) do |match|
      number = match[0]
      url.push "[##{number}]: https://github.com/teezily/t4b/pull/#{number}"

    end
    url.sort.join("\n")
  end
end

input = <<~STR
STR

puts Parser.new.generate_link(ARGV[0])
# puts Parser.new.generate_link(input)
