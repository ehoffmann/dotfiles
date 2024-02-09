#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'

# Backup some TZ project k8s conf

@timestamp = Time.now.strftime('%Y%m%d-%H%M%S')
@backup_dir = '/home/manu/backup/tz_deploys'
`mkdir -p #{@backup_dir}`

def backup_deploy(app, stage, dir)
  change_directory dir
  filename = "#{app}-#{stage}-deploy-#{@timestamp}.yml"
  cmd = "docker-compose run --rm web ./bin/kubectl-#{stage} get deploy #{app} -o yaml > #{@backup_dir}/#{filename}"
  system cmd
  if (status = $CHILD_STATUS.exitstatus).positive?
    puts "Script Error: #{status}"
    exit status
  end
  puts "Deploy backup DONE for #{filename}"
end

def backup_secret(app, stage, dir)
  change_directory dir
  filename = "#{app}-#{stage}-secret-#{@timestamp}.yml"
  cmd = "docker-compose run --rm web ./bin/kubectl-#{stage} get secret #{app} -o yaml > #{@backup_dir}/#{filename}"
  system cmd
  if (status = $CHILD_STATUS.exitstatus).positive?
    puts "Script Error: #{status}"
    exit status
  end
  puts "Secret backup DONE for #{filename}"
end

def change_directory(target_dir)
  Dir.chdir(target_dir)
rescue SystemCallError => e
  raise "Failed to change directory to #{target_dir}. Error: #{e.message}"
end

# TCO staging
# backup_deploy 'tco-web', :staging, '/home/manu/code/tz/tco'
# backup_deploy 'tco-worker', :staging, '/home/manu/code/tz/tco'
# backup_secret 'tco-secret', :staging, '/home/manu/code/tz/tco'

# TCO prod
# backup_deploy 'tco-web', :prod, '/home/manu/code/tz/tco'
# backup_deploy 'tco-worker', :prod, '/home/manu/code/tz/tco'
# backup_secret 'tco-secret', :prod, '/home/manu/code/tz/tco'

# T4B staging
backup_deploy 't4b-web', :staging, '/home/manu/code/tz/t4b'
backup_deploy 't4b-worker', :staging, '/home/manu/code/tz/t4b'
backup_secret 't4b-secret', :staging, '/home/manu/code/tz/t4b'

# T4B prod
backup_deploy 't4b-web', :prod, '/home/manu/code/tz/t4b'
backup_deploy 't4b-worker', :prod, '/home/manu/code/tz/t4b'
backup_deploy 't4b-worker-prio', :prod, '/home/manu/code/tz/t4b'
backup_secret 't4b-secret', :prod, '/home/manu/code/tz/t4b'
