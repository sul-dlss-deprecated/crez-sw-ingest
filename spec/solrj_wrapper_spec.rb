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
  
  context "add_vals_to_fld" do
    it "should do nothing if the field name or value is nil or of size 0" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, nil, ["val"])
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_vals_to_fld(sid, "", ["val"])
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_vals_to_fld(sid, "fldname", nil)
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_vals_to_fld(sid, "fldname", [])
      sid.isEmpty.should be_true
    end
    
    it "should create a new field when none exists" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, "single", ["val"])
      vals = sid["single"].getValues
      vals.size.should == 1
      vals[0].should == "val"
      @@solrj_wrapper.add_vals_to_fld(sid, "mult", ["val1", "val2"])
      vals = sid["mult"].getValues
      vals.size.should == 2
      vals[0].should == "val1"
      vals[1].should == "val2"
    end
    
    it "should keep the existing values when it adds a value to a field" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val"])
      vals = sid["fld"].getValues
      vals.size.should == 1
      vals[0].should == "val"
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val1", "val2"])
      vals = sid["fld"].getValues
      vals.size.should == 3
      vals.contains("val").should_not be_nil
      vals.contains("val1").should_not be_nil
      vals.contains("val2").should_not be_nil
    end
    
    it "should add all values, except those already present" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val"])
      vals = sid["fld"].getValues
      vals.size.should == 1
      vals[0].should == "val"
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val1", "val2", "val"])
      vals = sid["fld"].getValues
      vals.size.should == 3
      vals.contains("val").should_not be_nil
      vals.contains("val1").should_not be_nil
      vals.contains("val2").should_not be_nil
    end
  end # context add_vals_to_fld

end
