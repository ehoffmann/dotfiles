#!/usr/bin/env ruby

require 'English'

# Backup k8s deployment in local directory

deploys = ARGV
timestamp = Time.now.strftime('%Y%m%d-%H%M%S')

deploys.each do |deploy|
  cmd = "docker-compose run --rm web ./bin/kubectl-prod get deploy #{deploy} -o yaml > #{deploy}-#{timestamp}.yaml"
  puts cmd
  system cmd
  if (status = $CHILD_STATUS.exitstatus).positive?
    puts "Script Error: #{status}"
    exit status
  end
end
