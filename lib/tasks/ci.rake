desc "run continuous integration suite (tests, coverage, docs)" 

task :ci do 
  Rake::Task["doc"].invoke
  Rake::Task["rspec"].invoke
end
