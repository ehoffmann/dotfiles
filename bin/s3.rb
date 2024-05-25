#!/usr/bin/env ruby

# frozen_string_literal: true

require 'aws-sdk-s3'
require 'fog/aws' # v2 signature
require 'toml-rb'
require 'optparse'

# s3 list -c reprint_prod_bso_minio

class AwsSdkStorage
  def initialize(client_config)
    @client = Aws::S3::Client.new({
      access_key_id: client_config['access_key_id'],
      secret_access_key: client_config['secret_access_key'],
      region: client_config['region'],
      endpoint: client_config['endpoint'],
    }.compact)
  end

  def list(bucket, opts = {})
    resp = @client.list_objects_v2(bucket: bucket, max_keys: opts[:max] || DEFAULT_LIMIT)
    resp.contents.each { |object| puts object.key }
  end

  def count(bucket, opts)
    count = 0
    resp = @client.list_objects_v2(bucket: bucket)
    loop do
      count += resp.contents.size
      puts count if opts[:progress]
      break unless resp.is_truncated

      resp = @client.list_objects_v2(bucket: bucket, continuation_token: resp.next_continuation_token)
    end
    puts count
  end

  def method_missing(method, args)
    @client.send(method, args)
  end
end

class FogStorage
  def initialize(client_config)
    @client = Fog::Storage.new({
      provider: 'AWS',
      aws_access_key_id: client_config['access_key_id'],
      aws_secret_access_key: client_config['secret_access_key'],
      aws_signature_version: 2,
      endpoint: client_config['endpoint'],
      path_style: true,
      region: client_config['region']
    }.compact)
  end

  def list(bucket, opts = {})
    directory = @client.directories.get(bucket)
    files = directory.files.all(max_keys: opts[:max] || DEFAULT_LIMIT)
    files.each { |file| puts file.key }
  end

  def get_object(bucket: ,  key:)
    @client.get_object(bucket, key)
  end

  def count(bucket, opts)
    count = 0
    directory = @client.directories.get(bucket)

    directory.files.all.each do |file|
      count += 1
      puts count if opts[:progress]
    end

    puts count
  end
end

CONFIG_FILE = '~/.my_s3.toml'
OPERATIONS =  %w[list read count configs]
DEFAULT_LIMIT = 100

options = {}
OptionParser.new do |parser|
  parser.banner = 'Usage: s3 OPERATION [options]' \
    "\n Available operations: " \
    "\n\t list: bucket keys (limit by #{DEFAULT_LIMIT})" \
    "\n\t read: Read bucket object (--key) data" \
    "\n\t info: Display object (--key) info" \
    "\n\t count: Count bucket objects" \
  parser.on('-c', '--config CONFIG', "Config section in TOML config #{CONFIG_FILE}") do |c|
    options[:config] = c
  end
  parser.on('--list-configs', "List available configs in TOML config #{CONFIG_FILE}") do
    options[:list_configs] = true
  end
  parser.on('-k', '--key KEY', 'Object key (for read/write operations)') do |k|
    options[:key] = k
  end
  parser.on('-d', '--data DATA', 'Data to write (for write operation)') do |d|
    options[:data] = d
  end
  parser.on('-n', '--number NUMBER', Integer, 'Number of objects to list (for list operation)') do |n|
    options[:number] = n
  end
  parser.on('--progress', 'Display progress (for count operation)') do |p|
    options[:progress] = p
  end
end.parse!

if options[:list_configs]
  puts TomlRB.load_file(File.expand_path(CONFIG_FILE)).keys
  exit 0
end
options[:operation] = ARGV.shift
config = TomlRB.load_file(File.expand_path(CONFIG_FILE))[options[:config]]

raise "Configuration '#{options[:config]}' not found" unless config

storage = if config[:signature_version].to_i == 2
            FogStorage.new(config)
          else
            AwsSdkStorage.new(config)
          end

case options[:operation]
when 'list'
  storage.list(config['bucket'], max: options[:number])
when 'count'
  storage.count(config['bucket'], progress: options[:progress])
when 'read'
  resp = storage.get_object(bucket: config['bucket'], key: options[:key])
  puts resp.body.read
when 'info'
  resp = storage.get_object(bucket: config['bucket'], key: options[:key])
  puts JSON.pretty_generate(resp)
else
  puts "Unsupported operation: #{options[:operation]}"
end
