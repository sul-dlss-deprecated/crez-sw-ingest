require 'jettywrapper'
desc "run continuous integration suite (tests, coverage, docs)" 

task :ci do 
  Rake::Task["rspec"].invoke
  Rake::Task["doc"].invoke
end

task :clone_solrmarc do
  `git clone corn:/afs/ir/dev/dlss/git/searchworks/solrmarc-sw.git` unless Dir['solrmarc-sw']
end

desc "set up Solr for testing in jetty"
task :setup_jetty => :clone_solrmarc do
  Dir.chdir('solrmarc-sw') do 
    `git pull`
    # this is TEMPORARY until this code is merged to master!!!!
    `git checkout v2.5.0candidate`
    `ant crez_setup`
  end
end
task :setup_test_solr => :setup_jetty

desc "start jetty for running tests"
task :run_jetty do
  `rm -rf solrmarc-sw/test/jetty/solr/data/index`
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../solrmarc-sw/test/jetty'),
                                                :startup_wait => 15,
                                                :java_opts => "-Dsolr.data.dir=" + File.expand_path(File.dirname(__FILE__) + "../../../solrmarc-sw/test/jetty/solr")
                                                })
  error = Jettywrapper.start(jetty_params) 
end
task :jetty_start => :run_jetty
task :start_jetty => :run_jetty

desc  "stop jetty used for testing"
task :stop_jetty do
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../solrmarc-sw/test/jetty'),:startup_wait => 10})
  error = Jettywrapper.stop(jetty_params) 
end

task :jetty_stop => :stop_jetty

