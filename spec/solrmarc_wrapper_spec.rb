require 'solrmarc_wrapper'
require 'logger'

describe SolrmarcWrapper do
  
# FIXME:  need to use config/yml file to avoid hardcoding initialization values  
  
  before(:all) do
    solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    solr_url = "http://sw-solr-gen.stanford.edu:8983/solr"
    @@solrmarc_wrapper = SolrmarcWrapper.new(solrmarc_dist_dir, "sw_config.properties", solr_url)
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
  
  it "should log an error message when there is no document in the Solr index for the ckey" do
    lager = double("logger")
    @@solrmarc_wrapper.logger = lager
    lager.should_receive(:error).with("Can't find single SearchWorks Solr document with id aaa")
    @@solrmarc_wrapper.get_solr_input_doc("aaa")
  end
  
end
