require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:rspec) do |spec|
  spec.rspec_opts = ["-c", "-f progress", "-r ./spec/spec_helper.rb"]
end

desc "Run all specs, with jetty instance running"
task :rspec_wrapped => ['setup_jetty'] do
  jetty_dir = File.expand_path(File.dirname(__FILE__) + '../../../solrmarc-sw/test/jetty')
  require 'jettywrapper'
  jetty_params = Jettywrapper.load_config.merge({
    :jetty_home => jetty_dir,
    :solr_home => jetty_dir + '/solr',
    :java_opts => "-Dsolr.data.dir=" + jetty_dir + "/solr/data",
    :startup_wait => 45
  })
  error = Jettywrapper.wrap(jetty_params) do
    Rake::Task['index_sample_data'].invoke
    Rake::Task['rspec'].invoke
  end
  raise "TEST FAILURES: #{error}" if error
end


task :index_sample_data do
  require File.expand_path('../../lib/settings',  File.dirname(__FILE__))
  require 'rsolr'

  settings_env = ENV["SETTINGS"] ||= 'test'
  settings = Settings.new(settings_env)
  client = RSolr.connect(url: settings.solr_url, update_format: :xml)
  docs = JSON.parse(File.read(File.expand_path('../../spec/test_data/sample_solr_docs.json', File.dirname(__FILE__))))

  docs.each do |d|
    client.add d
  end

  client.commit
end
