#!/usr/bin/env ruby
# pull_and_ix_latest_w_passwd
# Pull the latest course reserve data file from jenson with password prompts
#  and index that file
# If we already have the latest file on jenson, do nothing.
# Naomi Dushay 2012-03-28

remote_dir = "/s/Dataload/SearchworksReserves/Data"
local_dir = "../data"

command = "ssh apache@jenson ls -t #{remote_dir}/reserves-data.* | head -1"
full_remote_file_name = `#{command}`.strip
file = File.basename(full_remote_file_name)

if File.exist?("#{local_dir}/#{file}")
  puts "already have latest data: #{file}"
else
  command = "scp -p apache@jenson:#{full_remote_file_name} #{local_dir}"
  `#{command}`
  command = "bin/crez-sw-ingest #{ARGV.join(' ')} #{local_dir}/#{file} \&\>#{local_dir}/logs/#{file}.log"
  `#{command}`
end
