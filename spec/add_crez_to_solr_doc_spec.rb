require 'add_crez_to_solr_doc'
require 'parse_crez_data'

describe AddCrezToSolrDoc do
  
  before(:all) do
    @@solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    @@solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    @@ckey_2_crez_info = p.ckey_2_crez_info
#    result_hash["111"].size.should == 2
#    result_hash["333"].size.should == 2
#    result_hash["555"].size.should == 2
#    result_hash["666"].size.should == 3
  end
  
  it "should do stuff" do
    a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
    a.should_not be_nil
    a.should be_an_instance_of(AddCrezToSolrDoc)
    a.ckey_2_crez_info.should be_an_instance_of(Hash)
    crez_info = a.ckey_2_crez_info["666"]
    crez_info.should be_an_instance_of(Array)
    crez_info[0].should be_an_instance_of(CSV::Row)
    pending "to be implemented"
  end

  it "should get the solr_input_doc" do
    a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
    sid = a.get_solr_input_doc("666")
    sid.should_not be_nil
    sid.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
  end

  it "should add all the correct lines from the sirsi data for a given ckey" do
    pending "to be implemented"
  end
  
  it "should add multiple ON_RESERVE lines with the same ckey" do
    pending "to be implemented"
  end
  
  it "should not add data when item reserve status isn't ON_RESERVE" do
    pending "to be implemented"
  end
  
  # blah blah about specific fields
end