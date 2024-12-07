#!/usr/bin/env ruby

# frozen_string_literal: true

# Examples
# s3 -c tsp_staging_amz -o list gpi .png |  ruby -ne 'puts $_.split("/").last' | uniq | wc -l
# s3 -c tsp_staging_amz -o list gpi .png |  ruby -ne 'puts $_.split("/").last' | sort | uniq | wc -l
# ruby bin/migrate_s3.rb tsp_staging_amz ehof_test
# ruby bin/migrate_s3.rb tsp_staging_amz tsp_staging_bso_minio -p '.png$'
# ruby bin/migrate_s3.rb tsp_prod_amz tsp_prod_bso_minio -p '.png$'

require 'aws-sdk-s3'
require 'toml-rb'
require 'optparse'

# Copy a source to destination S3
# migrate_s3 --help
class Program
  VERSION = '1.0.0'
  CONFIG_FILE = '~/.my_s3.toml'

  attr_accessor :source, :dest, :source_conf, :dest_conf, :source_bucket, :dest_bucket, :options

  def initialize
    self.options = {}
    parse_options

    self.source_conf = TomlRB.load_file(File.expand_path(CONFIG_FILE))[source]
    self.dest_conf = TomlRB.load_file(File.expand_path(CONFIG_FILE))[dest] if dest
    self.source_bucket = source_conf['bucket']
    self.dest_bucket = dest_conf['bucket'] if dest_conf

    puts options
    puts ARGV
    validate!
  end

  def parse_options
    OptionParser.new do |opts|
      opts.banner = 'Usage: migrate_s3 SOURCE [DEST] [options]'

      opts.on('-v', '--[no-]verbose', 'Run verbosely') do |o|
        options[:verbose] = o
      end

      opts.on('-p', '--pattern [PATTERN]', Regexp, 'Copy S3 object with key matching pattern only (regex)') do |o|
        options[:pattern] = o
      end

      opts.on('-l', '--local [DIR]', String, 'Directory for local file system copy') do |o|
        options[:local] = o
      end

      opts.on('-d', '--dry', 'Dry run, no real write') do
        puts 'Dry run, no real write'
        options[:dry] = true
        options[:verbose] = true
      end
    end.parse!
    self.source = ARGV[0]
    self.dest = ARGV[1]
  end

  def validate!
    # raise "You don't want to do this in prod!" if [source, dest].any? { |s| s =~ /prod/i }
    raise 'You must specify either config DEST or --local DIR' unless dest || options[:local]

    [[source, source_conf], [dest, dest_conf]].each do |name, conf|
      next unless name
      raise "Configuration '#{name}' not found" unless conf
    end
  end

  def call
    resp = source_client.list_objects_v2(bucket: source_bucket)
    count = 0
    loop do
      resp.contents.each do |obj|
        next if options[:pattern] && obj.key !~ options[:pattern]

        if options[:verbose]
          count += 1
          puts count
        end

        next if options[:dry] == true

        # body = source_client.get_object(bucket: source_bucket, key: obj.key).body.read
        tmp = source_client.get_object(bucket: source_bucket, key: obj.key)

        # puts JSON.pretty_generate(tmp)

        if options[:local]
          `mkdir -p #{options[:local]}`
          path, _, name = obj.key.rpartition('/')
          `mkdir -p #{path}`
          full_path = Pathname.new(options[:local]).join(path, name)
          File.write(full_path, tmp.body)
          puts "File #{obj.key} has been writen to #{full_path}" if options[:verbose]
        else
          dest_client.put_object(
            bucket: dest_bucket,
            key: obj.key,
            body: tmp.body,
            content_type: tmp.content_type,
            metadata: tmp.metadata
          )
          puts "File #{obj.key} has been uploaded to #{dest_bucket}" if options[:verbose]
        end
      end
      break unless resp.is_truncated

      resp = source_client.list_objects_v2(bucket: source_bucket, continuation_token: resp.next_continuation_token)
    end
  end

  private

  def source_client
    @source_client ||= client(source_conf)
  end

  def dest_client
    @dest_client ||= client(dest_conf)
  end

  def client(conf)
    Aws::S3::Client.new({
      access_key_id: conf['access_key_id'],
      secret_access_key: conf['secret_access_key'],
      region: conf['region'],
      endpoint: conf['endpoint'],
    }.compact)
  end
end

Program.new.call
