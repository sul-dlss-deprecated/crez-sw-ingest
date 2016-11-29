source 'https://rubygems.org'

ruby '1.9.3'

gem 'yard' 				# for javadoc-y documentation tags
gem 'RedCloth' 		# for textile formatting used in Readme
gem 'rake'
gem 'solrj_wrapper'
gem 'solrmarc_wrapper'

group :test do
	gem 'rspec', '2.99'
	gem 'simplecov', :require => false
	gem 'simplecov-rcov', :require => false
	gem 'rsolr'  # test that solr index updates are done correctly
	gem 'jettywrapper' # use jetty for Solr for integration tests
end
