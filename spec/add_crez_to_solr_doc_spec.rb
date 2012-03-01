require 'add_crez_to_solr_doc'
require 'parse_crez_data'

describe AddCrezToSolrDoc do
  
  before(:all) do
#    @@solrmarc_dist_dir = "/hudson/home/hudson/hudson/jobs/solrmarc-SW-solr3.5-dist/workspace/dist"
    @@solrmarc_dist_dir = "/Users/ndushay/searchworks/solrmarc-sw/dist"
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
  
  it "new_solr_flds object should start out as an empty Hash" do
    @@a.new_solr_flds.should be_an_instance_of(Hash)
    @@a.new_solr_flds.should be_empty
  end
  
  context "add_to_new_flds_hash" do
    before(:each) do
      @@a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
    end
    
    it "should not create a field if the only value to be added is nil" do
      @@a.add_to_new_flds_hash(:fname, nil)
      @@a.new_solr_flds.should be_empty
    end
    
    it "should not add a value when the CSV Row is missing the value" do
      crez_info = @@a.crez_info("666")
      @@a.add_to_new_flds_hash(:fname, crez_info[0][:fake])
      @@a.new_solr_flds.should be_empty
    end
    
    it "should not add a nil value to new_solr_flds" do
      @@a.add_to_new_flds_hash(:fname, "val1")
      @@a.new_solr_flds[:fname].size.should == 1
      @@a.new_solr_flds[:fname].should == ["val1"]
      @@a.add_to_new_flds_hash(:fname, nil)
      @@a.new_solr_flds[:fname].size.should == 1
      @@a.new_solr_flds[:fname].should == ["val1"]
    end
    
    it "should not add a duplicate value to new_solr_flds" do
      @@a.add_to_new_flds_hash(:fname, "val1")
      @@a.new_solr_flds[:fname].size.should == 1
      @@a.new_solr_flds[:fname].should == ["val1"]
      @@a.add_to_new_flds_hash(:fname, "val2")
      @@a.new_solr_flds[:fname].size.should == 2
      @@a.new_solr_flds[:fname].should == ["val1", "val2"]
      @@a.add_to_new_flds_hash(:fname, "val1")
      @@a.new_solr_flds[:fname].size.should == 2
      @@a.new_solr_flds[:fname].should == ["val1", "val2"]
    end
    
  end # add_to_new_flds_hash context
  
  context "get_compound_value_from_row" do
    it "should add the fields in order, with the indicated separator" do
      row = @@a.crez_info("666")[0]
      val = @@a.get_compound_value_from_row(row, [:course_id, :term, :ckey], "|")
      val.should == "COMPLIT-101|FALL|666"
      val = @@a.get_compound_value_from_row(row, [:course_id, :term, :ckey], " ")
      val.should == "COMPLIT-101 FALL 666"
      val = @@a.get_compound_value_from_row(row, [:course_id, :ckey, :term], " -!- ")
      val.should == "COMPLIT-101 -!- 666 -!- FALL"
    end
    
    it "should use an empty string for a missing column" do
      row = @@a.crez_info("666")[0]
      val = @@a.get_compound_value_from_row(row, [:fake, :term], " ")
      val.should == " FALL"
      val = @@a.get_compound_value_from_row(row, [:term, :fake], " ")
      val.should == "FALL "
      val = @@a.get_compound_value_from_row(row, [:course_id, :fake, :term], " -!- ")
      val.should == "COMPLIT-101 -!-  -!- FALL"
    end
  end

  it "should set dept to the course id(s) before the slash" do
    @@a.get_dept("COMPLIT-101").should == "COMPLIT"
    @@a.get_dept("MUSIC-2C-001").should == "MUSIC"
    @@a.get_dept("GEOPHYS 251").should == "GEOPHYS"
    @@a.get_dept("BIOHOPK-182H/323H").should == "BIOHOPK"
  end

  context "create_new_solr_flds_hash" do
    before(:each) do
      @@a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
    end
    
    it "should add all expected non-nil fields to the hash" do
      @@a.create_new_solr_flds_hash("666")
      fld_hash = @@a.new_solr_flds
      fld_hash[:crez_instructor_search].should == ["Saldivar, Jose David"]
      fld_hash[:crez_course_name_search].should == ["What is Literature?"]
      fld_hash[:crez_course_id_search].should == ["COMPLIT-101"]
      fld_hash[:crez_term_facet].should == ["FALL"]
      fld_hash[:crez_desk_facet].should == ["GREEN-RESV"]
      fld_hash[:dept_facet].should == ["COMPLIT"]
      fld_hash[:crez_course_facet].should == ["COMPLIT-101 FALL"]
      fld_hash[:crez_course_w_name_facet].should == ["COMPLIT-101 FALL What is Literature?"]
      fld_hash[:crez_display].should == ["COMPLIT-101 -|- What is Literature? -|- Saldivar, Jose David -|- FALL"]

      @@a.create_new_solr_flds_hash("555")
      fld_hash = @@a.new_solr_flds
      fld_hash[:crez_instructor_search].should == ["Harris, Bradford Cole", "Kreiner, Jamie K"]
      fld_hash[:crez_course_name_search].should == ["Saints in the Middle Ages"]
      fld_hash[:crez_course_id_search].should == ["HISTORY-41S", "HISTORY-211C"]
      fld_hash[:crez_term_facet].should == ["FALL"]
      fld_hash[:crez_desk_facet].should == ["GREEN-RESV"]
      fld_hash[:dept_facet].should == ["HISTORY"]
      fld_hash[:crez_course_facet].should == ["HISTORY-41S FALL", "HISTORY-211C FALL"]
      fld_hash[:crez_course_w_name_facet].should == ["HISTORY-41S FALL ", "HISTORY-211C FALL Saints in the Middle Ages"]
      fld_hash[:crez_display].should == ["HISTORY-41S -|-  -|- Harris, Bradford Cole -|- FALL", "HISTORY-211C -|- Saints in the Middle Ages -|- Kreiner, Jamie K -|- FALL"]
    end
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