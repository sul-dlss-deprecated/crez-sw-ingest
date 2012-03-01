require 'get_solrdoc_from_solrmarc'

describe GetSolrdocFromSolrmarc do
  
# FIXME:  need a way to avoid hardcoding the solrmarc directory  
  
  before(:all) do
    @@solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    @@solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    @@get_solrdoc_instance = GetSolrdocFromSolrmarc.new(@@solrmarc_dist_dir, "sw_config.properties")
  end
  
  it "should retrieve the SolrInputDoc generated from the marc record" do
    sid = @@get_solrdoc_instance.get_solr_input_doc("666")
    sid.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    sid["id"].getValue.should == "666"
    sid["title_full_display"].getValue.should_not be_nil
  end
  
  it "should have a SolrInputDoc with the non-stored fields present" do
    sid = @@get_solrdoc_instance.get_solr_input_doc("666")
    sid["title_245a_search"].getValue.should_not be_nil
  end

  it "should keep the existing values when it adds a value to a field" do
    pending "to be implement"
  end
  
end
