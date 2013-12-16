require 'jettywrapper'
desc "run continuous integration suite (tests, coverage, docs)" 

task :ci do 
  Rake::Task["rspec"].invoke
  Rake::Task["doc"].invoke
end

task :clone_solrmarc do
  `git clone corn:/afs/ir/dev/dlss/git/searchworks/solrmarc-sw.git`
# this doesn't work.  So sad.
#  `cd solrmarc-sw`
#  `git pull`
#  `ant crez_setup`
#  `cd ..`
  0
end

# this doesn't work.  so sad.
task :setup do
 `cd solrmarc-sw`
 `git pull`
 `ant crez_setup`
 `cd ..`
 File 
end

desc "start jetty for running tests"
task :run_jetty do
  jetty_params = Jettywrapper.load_config.merge({:jetty_home => File.expand_path(File.dirname(__FILE__) + '../../../solrmarc-sw/test/jetty'),
                                                :startup_wait => 10,
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

