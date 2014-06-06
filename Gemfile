source 'https://rubygems.org'

gem 'yard' 				# for javadoc-y documentation tags
gem 'RedCloth' 		# for textile formatting used in Readme
gem 'rake'
gem 'solrj_wrapper', :git => "https://github.com/sul-dlss/solrj_wrapper.git", :branch => "solr4.4"
gem 'solrmarc_wrapper'

group :test do
	gem 'rspec', '~>2'
	gem 'simplecov', :require => false
	gem 'simplecov-rcov', :require => false
	gem 'rsolr'  # test that solr index updates are done correctly
	gem 'jettywrapper' # use jetty for Solr for integration tests
end
