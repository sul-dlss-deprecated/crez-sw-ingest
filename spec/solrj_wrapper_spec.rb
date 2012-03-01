require 'solrj_wrapper'

describe SolrjWrapper do
  
# FIXME:  need a way to avoid hardcoding the solrj jars directory  
  
  before(:all) do
    solrj_jars_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist/lib"
#    solrj_jars_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist/lib"
    @@solrj_wrapper = SolrjWrapper.new(solrj_jars_dir)
  end
  
  it "should initialize a streaming_update_server object" do
    sus = @@solrj_wrapper.streaming_update_server
    sus.should be_an_instance_of(Java::OrgApacheSolrClientSolrjImpl::StreamingUpdateSolrServer)
  end
=begin
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
=end
  it "should keep the existing values when it adds a value to a field" do
    pending "to be implemented"
  end
  

end
