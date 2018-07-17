source 'https://rubygems.org'

gem 'yard' 				# for javadoc-y documentation tags
gem 'rake'
gem 'solrj_wrapper'
gem 'solrmarc_wrapper'

group :test do
	gem 'rspec', '~> 3'
	gem 'simplecov', :require => false
	gem 'rsolr'  # test that solr index updates are done correctly
	gem 'jettywrapper' # use jetty for Solr for integration tests
end

group :deploy do
  gem 'capistrano'
  gem 'capistrano-bundler'
  gem 'dlss-capistrano'
end
