require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
#  spec.pattern = FileList['spec/**/*_spec.rb']
  spec.pattern = 'spec/**/*_spec.rb'
end


=begin
#ruby 1.8.7

require 'spec/rake/spectask'

Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

# FIXME: not rcov
Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
  spec.rcov_opts = %w{--exclude spec\/*,gems\/*,ruby\/* --aggregate coverage.data}
end

task :clean do
  puts 'Cleaning old coverage.data'
  FileUtils.rm('coverage.data') if(File.exists? 'coverage.data')
end
=end