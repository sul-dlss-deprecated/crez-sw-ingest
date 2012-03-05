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
    @@sid555 = @@a.solr_input_doc("555")
    @@sid666 = @@a.solr_input_doc("666")
  end

  it "should retrieve the solr_input_doc for a ckey" do
    @@sid666.should_not be_nil
    @@sid666.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    @@sid666["id"].getValue.should == "666"
  end
  
  it "should raise an exception when there is no document in the Solr index for the ckey" do
    expect {@@a.solr_input_doc("aaa")}.to raise_error("Can't find document for ckey aaa")
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

  # FIXME:  this needs a translation table
  it "should set dept to the course id(s) before the slash" do
    @@a.get_dept("COMPLIT-101").should == "COMPLIT"
    @@a.get_dept("MUSIC-2C-001").should == "MUSIC"
    @@a.get_dept("GEOPHYS 251").should == "GEOPHYS"
    @@a.get_dept("BIOHOPK-182H/323H").should == "BIOHOPK"
  end

  context "create_new_solr_flds_hash" do
    before(:all) do
      @@a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, @@ckey_2_crez_info)
    end
    
    it "should add all expected non-nil fields to the hash" do
      @@a.create_new_solr_flds_hash(@@a.crez_info("666"))
      fld_hash = @@a.new_solr_flds
      fld_hash[:crez_instructor_search].should == ["Saldivar, Jose David"]
      fld_hash[:crez_course_name_search].should == ["What is Literature?"]
      fld_hash[:crez_course_id_search].should == ["COMPLIT-101"]
      fld_hash[:crez_term_facet].should be_nil
      fld_hash[:crez_desk_facet].should == ["Green Reserves"]
      fld_hash[:dept_facet].should == ["COMPLIT"]
      fld_hash[:crez_course_facet].should == ["COMPLIT-101 What is Literature?"]
      fld_hash[:crez_display].should == ["COMPLIT-101 -|- What is Literature? -|- Saldivar, Jose David"]

      @@a.create_new_solr_flds_hash(@@a.crez_info("555"))
      fld_hash = @@a.new_solr_flds
      fld_hash[:crez_instructor_search].should == ["Harris, Bradford Cole", "Kreiner, Jamie K"]
      fld_hash[:crez_course_name_search].should == ["Saints in the Middle Ages"]
      fld_hash[:crez_course_id_search].should == ["HISTORY-41S", "HISTORY-211C"]
      fld_hash[:crez_term_facet].should be_nil
      fld_hash[:crez_desk_facet].should == ["Green Reserves"]
      fld_hash[:dept_facet].should == ["HISTORY"]
      fld_hash[:crez_course_facet].should == ["HISTORY-41S ", "HISTORY-211C Saints in the Middle Ages"]
      fld_hash[:crez_display].should == ["HISTORY-41S -|-  -|- Harris, Bradford Cole", "HISTORY-211C -|- Saints in the Middle Ages -|- Kreiner, Jamie K"]
    end
  end
  
  context "get_item_display_val" do

    it "should return nil if there is no matching barcode" do
      @@a.get_item_display_val("fake", @@sid666).should be_nil
    end

    it "should find an item_display field with matching barcode" do
      matching_val = @@a.get_item_display_val("36105041846424", @@sid666)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105041846424"
      sid = @@a.solr_input_doc("9340596")
      matching_val = @@a.get_item_display_val("36105217077085", sid)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105217077085"
      matching_val = @@a.get_item_display_val("36105217629935", sid)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105217629935"
    end
  end
  
  it "should raise an exception when there is no matching item for the barcode per Course Reserve" do
    pending "to be implemented"
    expect {@@a.solr_input_doc("666")}.to raise_error("Can't find item for barcode aaa")
  end
  
  context "redo_building_facet" do

    it "should use the Course Reserve value over the item_display value" do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/multrezdesk.csv', File.dirname(__FILE__)))
      a = AddCrezToSolrDoc.new(@@solrmarc_dist_dir, p.ckey_2_crez_info)
      sid9262146 = a.solr_input_doc("9262146")
      orig_vals = sid9262146["building_facet"].getValues
      orig_vals.size.should == 2
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("Art & Architecture").should be_true
      a.redo_building_facet(sid9262146, a.crez_info("9262146"))
      new_vals = sid9262146["building_facet"].getValues
      new_vals.size.should == 2
      new_vals.contains("Physics").should be_true
      new_vals.contains("Art & Architecture").should be_true
      
      sid8707706 = a.solr_input_doc("8707706")
      orig_vals = sid8707706["building_facet"].getValues
      orig_vals.size.should == 3
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("Art & Architecture").should be_true
      orig_vals.contains("Cubberley (Education)").should be_true
      a.redo_building_facet(sid8707706, a.crez_info("8707706"))
      new_vals = sid8707706["building_facet"].getValues
      new_vals.size.should == 2
      new_vals.contains("Green (Humanities & Social Sciences)").should be_true
      new_vals.contains("Physics").should be_true
    end

    it "should raise an exception when there is no document in the Solr index for the ckey" do
      expect {@@a.solr_input_doc("aaa")}.to raise_error("Can't find document for ckey aaa")
    end

    
    it "should ignore a (un-overridden) library value missing from the library translation table" do
      pending "to be implemented"
    end
    
    it "should use the crez loc for library loc without translation" do
      pending "to be implemented"
    end
    
    it "should retain the library loc if only some items with that loc are overridden" do
      pending "to be implemented"
    end

  end
  
  context "updating existing solr doc fields" do

    it "should add the Course Reserve value to the Access facet" do
      sid = @@a.solr_input_doc("666")
      sid["access_facet"].getValues.contains("Course Reserve").should be_false
      @@a.add_crez_val_to_access_facet(sid)
      sid["access_facet"].getValues.contains("Course Reserve").should be_true
    end

    it "should add stuff to the item_display field" do
      pending "to be implemented"
    end

    it "should use the reserve desk for the library (location) facet value" do
      pending "to be implemented"
    end
    
    it "should add the building if there are other non-reserve items at the orig building" do
      pending "to be implemented"
    end
    
    it "should remove the old building value if there are no more items there" do
      pending "to be implemented"
    end
    
  end
  
  
  
end