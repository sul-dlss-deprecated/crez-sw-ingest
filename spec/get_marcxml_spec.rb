require 'get_marcxml.rb'
require 'rsolr'

describe GetMarcxml do

  # reduce to appropriate specs;  call  g = GetMarcxml.new fewer times?

=begin
  it "should point to config/solr.yml" do
    g = GetMarcxml.new
    g.solr_config_file.should match(/config\/solr\.yml$/)
  end
=end
  
  it "should get the solr url from config/solr.yml" do
    g = GetMarcxml.new
    g.solr_url.should match(/^http:\/\//)
  end
  
  it "should set up an Rsolr connection to solr_url" do
    g = GetMarcxml.new
    g.solr.should be_an_instance_of(RSolr::Client)
    g.solr_url.should match(g.solr.uri.host)
  end

  it "should handle an invalid solr url nicely" do
    pending "to be implemented"
  end

  it "should get a response from valid solr url" do
    g = GetMarcxml.new
    solr_doc = g.get_solr_document('666')
    solr_doc.should be_an_instance_of(RSolr::Response)
    solr_doc[:id].should == '666'
    pending "to be implemented"
  end
  
  it "should get a single document in the Solr response" do
    
  end
  
  
  it "should get a field named marcxml in the response" do
    pending "to be implemented"
  end

  it "should handle non-existing ckeys nicely" do
    pending "to be implemented"
  end
  
  it "should retrieve parsable marc (from SearchWorks Solr)" do
    pending "to be implemented"
  end
  
  it "should retrieve marc that is parsable by SolrMarc" do
    pending "to be implemented"
  end
  
  
end