require File.expand_path('../spec_helper', __FILE__)
require 'solrj_wrapper'

describe SolrjWrapper do
  
  before(:all) do
    @@solrj_wrapper = SolrjWrapper.new(@@settings.solrj_jar_dir, @@settings.solr_url, @@settings.solrj_queue_size, @@settings.solrj_num_threads)
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

  context "add_val_to_fld" do
    it "should do nothing if the field name or value is nil or of size 0" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_val_to_fld(sid, nil, "val")
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_val_to_fld(sid, "", "val")
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_val_to_fld(sid, "fldname", nil)
      sid.isEmpty.should be_true
      @@solrj_wrapper.add_val_to_fld(sid, "fldname", [])
      sid.isEmpty.should be_true
    end
    
    it "should create a new field when none exists" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_val_to_fld(sid, "single", "val")
      vals = sid["single"].getValues
      vals.size.should == 1
      vals[0].should == "val"
    end
    
    it "should keep the existing values when it adds a value to a field" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val1", "val2"])
      @@solrj_wrapper.add_val_to_fld(sid, "fld", "val")
      vals = sid["fld"].getValues
      vals.size.should == 3
      vals.contains("val").should_not be_nil
      vals.contains("val1").should_not be_nil
      vals.contains("val2").should_not be_nil
    end
    
    it "should add all values, except those already present" do
      sid = Java::OrgApacheSolrCommon::SolrInputDocument.new
      @@solrj_wrapper.add_vals_to_fld(sid, "fld", ["val1", "val2", "val"])
      @@solrj_wrapper.add_val_to_fld(sid, "fld", "val")
      vals = sid["fld"].getValues
      vals.size.should == 3
      vals.contains("val").should_not be_nil
      vals.contains("val1").should_not be_nil
      vals.contains("val2").should_not be_nil
    end
  end # context add_vals_to_fld

end
