require 'solrj_wrapper'
require 'solrmarc_wrapper'

describe SolrjWrapper do
  
# FIXME:  need a way to avoid hardcoding the solrj jars directory  
  
  before(:all) do
    solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    solrj_jars_dir = solrmarc_dist_dir + "/lib"
    @@solrj_wrapper = SolrjWrapper.new(solrj_jars_dir)
    @@solrmarc_wrapper = SolrmarcWrapper.new(solrmarc_dist_dir, "sw_config.properties")
  end
  
  it "should initialize a streaming_update_server object" do
    sus = @@solrj_wrapper.streaming_update_server
    sus.should be_an_instance_of(Java::OrgApacheSolrClientSolrjImpl::StreamingUpdateSolrServer)
  end
  
=begin
    sid["id"].getValue.should == "666"
    sid["title_full_display"].getValue.should_not be_nil
    sid["title_245a_search"].getValue.should_not be_nil
=end

  context "add_value_to_field" do
    before(:each) do
      @@sid = @@solrmarc_wrapper.get_solr_input_doc("666")
    end
    
    it "should do nothing if the field name or value is nil or the empty string" do
      @@sid_dup = @@sid.dup
      num_flds = @@sid.keys.size
      @@solrj_wrapper.add_value_to_field(@@sid_dup, nil, "val")
      @@sid_dup.keys.size.should == num_flds
      @@solrj_wrapper.add_value_to_field(@@sid_dup, "", "val")
      @@sid_dup.keys.size.should == num_flds
      @@solrj_wrapper.add_value_to_field(@@sid_dup, "fldname", nil)
      @@sid_dup.keys.size.should == num_flds
      @@solrj_wrapper.add_value_to_field(@@sid_dup, "fldname", "")
      @@sid_dup.keys.size.should == num_flds
    end
    
    it "should create a new field when none exists" do
      
    end

    it "should create a new field " do

    end

    it "should keep the existing values when it adds a value to a field" do
      sid = @@solrmarc_wrapper.get_solr_input_doc("666")
      # single valued field

      # multivalued field
    end
    
    it "should add multiple values to the field" do
      
    end
    
  end

  

end
