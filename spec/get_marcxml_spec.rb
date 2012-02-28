require 'get_marcxml.rb'
require 'rsolr'
require 'marc'

describe GetMarcxml do

  # reduce to appropriate specs;  call  g = GetMarcxml.new before all tests?

=begin
  it "should point to config/solr.yml" do
    g = GetMarcxml.new
    g.solr_config_file.should match(/config\/solr\.yml$/)   # not a method  -- only an instance var
  end
=end
  
  it "should set up an Rsolr connection to solr_url" do
    g = GetMarcxml.new
    g.solr_url.should match(/^http:\/\//)
    g.solr.should be_an_instance_of(RSolr::Client)
    g.solr_url.should match(g.solr.uri.host)
  end

  it "should handle an invalid solr url nicely" do
    pending "to be implemented"
  end

  it "should get a response from valid solr url" do
    g = GetMarcxml.new
    solr_doc = g.get_solr_document('666')
    solr_doc.should be_an_instance_of(Hash)
    solr_doc["id"].should == '666'
  end
  
  it "should retrieve parsable marcxml" do
    g = GetMarcxml.new
    marcxml = g.get_marcxml('666')
    marcxml.should be_an_instance_of(String)
    reader = MARC::XMLReader.new(StringIO.new(marcxml))
    rec = reader.entries[0]    
    rec['001'].value.should == 'a666'
    rec['245']['a'].should_not be_nil
  end
  
  it "should handle non-existing ckeys nicely" do
    pending "to be implemented"
  end
  
end