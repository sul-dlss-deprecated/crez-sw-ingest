require 'marc_to_solr_doc'

describe MarcToSolrDoc do
  
  it "should load everything necessary to call SolrMarc" do
    m = MarcToSolrDoc.new("/Users/ndushay/searchworks/solrmarc-sw/dist", "sw_config.properties")
    d = m.get_solr_input_doc("666")
    d.should_not be_nil
    d.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    d["id"].getValue.should == "666"
  end
  
  it "should retrieve the SolrDoc generated from the marc record" do
    m = MarcToSolrDoc.new("/Users/ndushay/searchworks/solrmarc-sw/dist", "sw_config.properties")
    d = m.get_solr_input_doc("666")
    d.should_not be_nil
    d.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    d["id"].getValue.should == "666"
    d["title_full_display"].getValue.should_not be_nil
  end
  
  it "should have a SolrDoc with the non-stored fields present" do
    m = MarcToSolrDoc.new("/Users/ndushay/searchworks/solrmarc-sw/dist", "sw_config.properties")
    d = m.get_solr_input_doc("666")
    d["title_245a_search"].getValue.should_not be_nil
  end

  it "should call SolrMarc for each marc record" do
    pending "to be implemented"
  end
  
end


