require 'add_crez_to_solr_doc'
require 'parse_crez_data'

describe AddCrezToSolrDoc do
  
  before(:all) do
    @@solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
#    @@solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    @@ckey_2_crez_info = p.ckey_2_crez_info
    @@a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
#    result_hash["111"].size.should == 2
#    result_hash["333"].size.should == 2
#    result_hash["555"].size.should == 2
#    result_hash["666"].size.should == 3
  end
  
  it "should do stuff" do
    @@a.should_not be_nil
    @@a.should be_an_instance_of(AddCrezToSolrDoc)
    @@a.ckey_2_crez_info.should be_an_instance_of(Hash)
  end

  it "should retrieve the solr_input_doc for a ckey" do
    sid = @@a.solr_input_doc("666")
    sid.should_not be_nil
    sid.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    sid["id"].getValue.should == "666"
  end
  
  it "should retrieve the array of crez_info csv rows for a ckey" do
    crez_info = @@a.crez_info("666")
    crez_info.should be_an_instance_of(Array)
    crez_info[0].should be_an_instance_of(CSV::Row)
  end
  
  it "add_val_from_row should cope with the first value (create the Array) and repeated values (de-dupped)" do
    crez_info = @@a.crez_info("666")
    v = @@a.add_val_from_row(nil, crez_info[0], :ckey)
    v.should be_an_instance_of(Array)
    v.size.should == 1
    v[0].should == "666"
    v = @@a.add_val_from_row(v, crez_info[0], :ckey)
    v.size.should == 1
    v = @@a.add_val_from_row(v, crez_info[0], :rez_desk)
    v.size.should == 2
  end
  
  it "add_val_from_row should create empty array for single missing value" do
    crez_info = @@a.crez_info("666")
    v = @@a.add_val_from_row(nil, crez_info[0], :fake)
    v.empty?.should == true
  end
  
  it "add_compound_val_from_row should add the fields in order, with the indicated separator" do
    crez_info = @@a.crez_info("666")
    v = @@a.add_compound_val_from_row(nil, crez_info[0], [:fake, :term], " ")
    v.should be_an_instance_of(Array)
    v.size.should == 1
    v[0].should == " FALL"
    v = @@a.add_compound_val_from_row(v, crez_info[1], [:course_id, :term], " -!- ")
    v.size.should == 2
    v[1].should == "COMPLIT-101 -!- FALL"
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