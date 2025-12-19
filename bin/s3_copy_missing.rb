#!/usr/bin/env ruby

# frozen_string_literal: true

require 'aws-sdk-s3'

bucket_name = 'xxx'

# List AMZ objects
amz_creds = {
  access_key_id: "xxx",
  secret_access_key: "xxx",
  region: 'eu-west-1',
}
amz_client = Aws::S3::Client.new(amz_creds)

# List BSO objects
bso_creds = {
  access_key_id: "xxx",
  secret_access_key: "xxx",
  endpoint: 'https://xxx.s3.eu-west-1.bso.st',
  region: 'eu-west-1'
}
bso_client = Aws::S3::Client.new(bso_creds)

keys = File.read('keys.txt').split("\n")

not_found = []
created = []
keys.each.with_index do |key, i|
  puts key
  puts i
  begin
    obj = bso_client.head_object(bucket: bucket_name, key: key.chomp)
  rescue Aws::S3::Errors::NotFound
    not_found << key
    source_obj = amz_client.get_object(bucket: bucket_name, key: key.chomp)
    bso_client.put_object(
      bucket: bucket_name,
      key: key.chomp,
      body: source_obj.body,
      content_type: source_obj.content_type,
      metadata: source_obj.metadata
    )
    puts 'created'
    created << key
  end
end
puts keys.count
puts not_found.count
puts created.count
