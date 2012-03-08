require 'solrmarc_wrapper'
require 'logger'
require 'settings'

describe SolrmarcWrapper do
  
  before(:all) do
    env = ENV['settings'] || 'test'
    config = Settings.new(env)
    @@solrmarc_wrapper = SolrmarcWrapper.new(config.solrmarc_dist_dir, config.solrmarc_conf_props_file, config.solr_url)
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
