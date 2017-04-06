crez-sw-ingest
==============

[![Dependency Status](https://gemnasium.com/badges/github.com/sul-dlss/crez-sw-ingest.svg)](https://gemnasium.com/github.com/sul-dlss/crez-sw-ingest)

Course Reserve (data from Sirsi) to SearchWorks (Solr) Ingest (Software).

This software

- pulls the latest course reserve data feed from Jenson
- extracts the items with reserve status “ON\_RESERVE”
- gets the raw marcxml for the implicated ckeys
- runs the marcxml through Stanford’s SolrMarc and grabs the generated Solr Document before it is written to the index
- adds the course reserve information to the Solr Document
- updates the Solr Document in the index

It also removes stale course reserve data from the SearchWorks index.

Requirements
------------

JRuby 1.7, configured to use Ruby 1.9 (which it is by default)

Installation/Setup
------------------

```
      git clone https://github.com/sul-dlss/crez-sw-ingest.git
      cd crez-sw-ingest
      rvm use jruby-1.7
      bundle install
      rake setup_test_solr
```

How to Use
----------

1. Adjust config/settings.yml.
2. Make sure you are using jruby 1.7, configured to use Ruby 1.9
3. Make sure you are using the latest solrmarc-sw code.

```
      rvm use jruby-1.7
      rake setup_test_solr
```

(run script of choice in bin folder.)

How to Test
-----------

1. Adjust config/settings.yml.
2. Make sure you are using jruby 1.7, configured to use Ruby 1.9
3. Make sure you are using the latest solrmarc-sw code.

```
      rvm use jruby-1.7
      rake setup_test_solr
        rake run_jetty
      rake ci
      rake stop_jetty
```

Note: sometimes if you don’t wait long enough after starting jetty, the Solr index gets locked.
You can fix this by

```
        rake stop_jetty
        rm -rf solrmarc-sw/test/jetty/solr/data/index
```
