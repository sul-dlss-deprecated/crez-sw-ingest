require 'jettywrapper'
desc "run continuous integration suite (tests, coverage, docs)" 

task :ci do 
  Rake::Task["rspec"].invoke
  Rake::Task["doc"].invoke
end

task :clone_solrmarc do
  `git clone corn:/afs/ir/dev/dlss/git/searchworks/solrmarc-sw.git`
  `cd solrmarc-sw`
  `ant dist_site`
  `cd ..`
  0
end

task :copy_configs do
 `cd solrmarc-sw`
 `ant site_setup_test_jetty`
 `cp test/jetty/solr/conf/solrconfig-no-repl.xml test/jetty/solr/conf/solrconfig.xml`
 `cd ..`
 File 
end

task :run_jetty do
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../solrmarc-sw/test/jetty'),:startup_wait => 10})
  error = Jettywrapper.start(jetty_params) 
end