require 'get_solrdoc_from_solrmarc'

describe GetSolrdocFromSolrmarc do
  
  it "should retrieve the SolrInputDoc generated from the marc record" do
    m = GetSolrdocFromSolrmarc.new("/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist", "sw_config.properties")
    d = m.get_solr_input_doc("666")
    d.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    d["id"].getValue.should == "666"
    d["title_full_display"].getValue.should_not be_nil
  end
  
  it "should have a SolrInputDoc with the non-stored fields present" do
    m = GetSolrdocFromSolrmarc.new("/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist", "sw_config.properties")
    d = m.get_solr_input_doc("666")
    d["title_245a_search"].getValue.should_not be_nil
  end
  
end
