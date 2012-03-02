require 'solrmarc_wrapper'

describe SolrmarcWrapper do
  
# FIXME:  need a way to avoid hardcoding the solrmarc directory  
  
  before(:all) do
    solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    @@solrmarc_wrapper = SolrmarcWrapper.new(solrmarc_dist_dir, "sw_config.properties")
  end
  
  it "should retrieve the SolrInputDoc generated from the marc record" do
    sid = @@solrmarc_wrapper.get_solr_input_doc("666")
    sid.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    sid["id"].getValue.should == "666"
    sid["title_full_display"].getValue.should_not be_nil
  end
  
  it "should have a SolrInputDoc with the non-stored fields present" do
    sid = @@solrmarc_wrapper.get_solr_input_doc("666")
    sid["title_245a_search"].getValue.should_not be_nil
  end
  
  it "should raise an exception when there is no document in the Solr index for the ckey" do
    expect {@@solrmarc_wrapper.get_solr_input_doc("aaa")}.to raise_error("Can't find document for ckey aaa")
  end
  
end
