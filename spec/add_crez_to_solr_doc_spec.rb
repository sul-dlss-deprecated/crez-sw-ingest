require File.expand_path('../spec_helper', __FILE__)
require 'add_crez_to_solr_doc'
require 'parse_crez_data'
require 'logger'

describe AddCrezToSolrDoc do
  
  before(:all) do
    @@solrmarc_wrapper = SolrmarcWrapper.new(@@settings.solrmarc_dist_dir, @@settings.solrmarc_conf_props_file, @@settings.solr_url)
    @@solrj_wrapper = SolrjWrapper.new(@@settings.solrj_jar_dir, @@settings.solr_url, @@settings.solrj_queue_size, @@settings.solrj_num_threads)
    @@p = ParseCrezData.new
    @@p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    @@ckey_2_crez_info = @@p.ckey_2_crez_info
    @@a = AddCrezToSolrDoc.new(@@ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
    @@sid555 = @@a.solr_input_doc("555")
    @@sid666 = @@a.solr_input_doc("666")
  end

  it "should retrieve the solr_input_doc for a ckey" do
    @@sid666.should_not be_nil
    @@sid666.should be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    @@sid666["id"].getValue.should == "666"
  end
  
  it "should retrieve the array of crez_info csv rows for a ckey" do
    crez_info = @@a.crez_info("666")
    crez_info.should be_an_instance_of(Array)
    crez_info[0].should be_an_instance_of(CSV::Row)
  end
  
  it "should log an error message when no item matches the barcode from Course Reserve data" do
    lager = double("logger")
    @@a.logger = lager
    lager.should_receive(:error).with("Solr Document for 666 has no item with barcode 36105044915804")
    lager.should_receive(:error).with("Solr Document for 666 has no item with barcode 36105044915807")
    lager.should_receive(:error).with("Solr Document for 666 has no item with barcode 36105044915808")
    @@a.add_crez_info_to_solr_doc("666")
  end
    
  it "should log an error message when there are no csv rows for a ckey" do
    lager = double("logger")
    @@a.logger = lager
    lager.should_receive(:error).with("Ckey 777 has no rows in the Course Reserves csv data")
    @@a.add_crez_info_to_solr_doc("777")
  end
  
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
      val = @@a.get_compound_value_from_row(row, [:course_id, :fake, :term], " -|- ")
      val.should == "COMPLIT-101 -|-  -|- FALL"
    end
  end

  # FIXME:  this needs a translation table
  it "should set dept to the course id(s) before the slash" do
    @@a.get_dept("COMPLIT-101").should == "COMPLIT"
    @@a.get_dept("MUSIC-2C-001").should == "MUSIC"
    @@a.get_dept("GEOPHYS 251").should == "GEOPHYS"
    @@a.get_dept("BIOHOPK-182H/323H").should == "BIOHOPK"
  end

  context "get_matching_item_from_doc" do
    it "should return nil if there is no matching barcode" do
      @@a.get_matching_item_from_doc("fake", @@sid666).should be_nil
    end

    it "should find an item_display field with matching barcode" do
      matching_val = @@a.get_matching_item_from_doc("36105041846424", @@sid666)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105041846424"
      sid = @@a.solr_input_doc("9340596")
      matching_val = @@a.get_matching_item_from_doc("36105217077085", sid)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105217077085"
      matching_val = @@a.get_matching_item_from_doc("36105217629935", sid)
      matching_val.split("-|-").size.should == 10
      matching_val.split("-|-")[0].strip.should == "36105217629935"
    end
  end
  
  context "redo_building_facet" do
    before(:all) do
      @@p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      @@ac2sd = AddCrezToSolrDoc.new(@@ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
    end

    it "should use the Course Reserve rez_desk value instead of the item_display library value" do
      sid9262146 = @@ac2sd.solr_input_doc("9262146")
      orig_vals = sid9262146["building_facet"].getValues
      orig_vals.size.should == 2
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("Art & Architecture").should be_true
      @@ac2sd.redo_building_facet(sid9262146, @@ac2sd.crez_info("9262146"))
      new_vals = sid9262146["building_facet"].getValues
      new_vals.size.should == 2
      new_vals.contains("Physics").should be_true
      new_vals.contains("Art & Architecture").should be_true
      
      sid8707706 = @@ac2sd.solr_input_doc("8707706")
      orig_vals = sid8707706["building_facet"].getValues
      orig_vals.size.should == 3
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("Art & Architecture").should be_true
      orig_vals.contains("Cubberley (Education)").should be_true
      @@ac2sd.redo_building_facet(sid8707706, @@ac2sd.crez_info("8707706"))
      new_vals = sid8707706["building_facet"].getValues
      new_vals.size.should == 2
      new_vals.contains("Green (Humanities & Social Sciences)").should be_true
      new_vals.contains("Physics").should be_true
    end

    it "should retain the library loc if only some items with that loc are overridden" do
      sid8834492 = @@ac2sd.solr_input_doc("8834492")
      orig_vals = sid8834492["building_facet"].getValues
      orig_vals.size.should == 2
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("SAL3 (Off-campus)").should be_true
      @@ac2sd.redo_building_facet(sid8834492, @@ac2sd.crez_info("8834492"))
      new_vals = sid8834492["building_facet"].getValues
      new_vals.size.should == 3
      orig_vals.contains("Green (Humanities & Social Sciences)").should be_true
      orig_vals.contains("SAL3 (Off-campus)").should be_true
      new_vals.contains("Physics").should be_true
    end
    
    it "should retain the library if the crez location is for the same library" do
      sid9423045 = @@ac2sd.solr_input_doc("9423045")
      orig_vals = sid9423045["building_facet"].getValues
      orig_vals.size.should == 1
      orig_vals[0].should == "Green (Humanities & Social Sciences)"
      @@ac2sd.redo_building_facet(sid9423045, @@ac2sd.crez_info("9423045"))
      new_vals = sid9423045["building_facet"].getValues
      new_vals.size.should == 1
      new_vals[0].should == "Green (Humanities & Social Sciences)"
    end

    it "should ignore a crez loc with no translation (use the library from item_display)" do
      sid888 = @@ac2sd.solr_input_doc("888")
      orig_vals = sid888["building_facet"].getValues
      orig_vals.size.should == 1
      orig_vals[0].should == "Music"
      @@ac2sd.redo_building_facet(sid888, @@ac2sd.crez_info("888"))
      new_vals = sid888["building_facet"].getValues
      new_vals.size.should == 1
      new_vals[0].should == "Music"
      # no translation for library in item_display either
      sid9434391 = @@ac2sd.solr_input_doc("9434391")
      sid9434391["building_facet"].should be_nil
      @@ac2sd.redo_building_facet(sid9434391, @@ac2sd.crez_info("9434391"))
      sid9434391["building_facet"].should be_nil
    end
    
    it "should create a building_facet value from the crez loc when there was no original value from item_display" do
      sid9518589 = @@ac2sd.solr_input_doc("9518589")
      sid9518589["building_facet"].should be_nil
      @@ac2sd.redo_building_facet(sid9518589, @@ac2sd.crez_info("9518589"))
      new_vals = sid9518589["building_facet"].getValues
      new_vals.size.should == 1
      new_vals[0].should == "Physics"
    end

    it "should ignore a (un-overridden) library value missing from the library translation table" do
      pending "need a record with both an overridden and an unoverridden case ..."
    end
  end # context "redo_building_facet"

  context "update_building_facet" do
    before(:all) do
      @@p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
    end
    
    it "should only call redo_building_facet once" do
      @@a.should_receive(:redo_building_facet).once
      sid8707706 = @@a.solr_input_doc("8707706")
      @@a.update_building_facet(sid8707706, @@a.crez_info("8707706"))
    end

    it "should call redo_building_facet if there is a rez desk and there was no building_facet value" do
      @@a.should_receive(:redo_building_facet).once
      sid9518589 = @@a.solr_input_doc("9518589")
      @@a.update_building_facet(sid9518589, @@a.crez_info("9518589"))
    end
    
    it "should not call redo_building_facet if no crez rez-desk differs from library in item_display field" do
      @@a.should_not_receive(:redo_building_facet)
      sid4286782 = @@a.solr_input_doc("4286782")
      @@a.update_building_facet(sid4286782, @@a.crez_info("4286782"))
    end
    
    it "should not call redo_building_facet if the only rez_desk values don't map to anything" do
      @@a.should_not_receive(:redo_building_facet)
      sid9434391 = @@a.solr_input_doc("9434391")
      @@a.update_building_facet(sid9434391, @@a.crez_info("9434391"))
    end
  end # context update_building_facet


  it "should add the Course Reserve value to the Access facet" do
    sid = @@a.solr_input_doc("666")
    sid["access_facet"].getValues.contains("Course Reserve").should be_false
    @@a.add_crez_val_to_access_facet(sid)
    sid["access_facet"].getValues.contains("Course Reserve").should be_true
  end
  
  context "append_crez_info_to_item_disp" do
    before(:each) do
      @@p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      @@crez8834492_row0 = @@p.ckey_2_crez_info["8834492"][0]
      @@item_display_val = @@sid666["item_display"].getValues.first
      @@new_val = @@a.append_crez_info_to_item_disp(@@item_display_val, @@crez8834492_row0)
    end
    
    it "should add the right number of separators to the item_display value" do
      @@item_display_val.split("-|-").size.should == 10
      @@new_val.split("-|-").size.should == 13
    end
    
    it "should append course id, rez_desk and loan period to the item_display value" do
      @@new_val.should == @@item_display_val + " -|- COMPLIT-101 -|- Physics Reserves -|- 2 Hours"
    end

    it "should translate the rez desk to a user friendly string" do
      @@new_val.split("-|-")[11].strip.should == "Physics Reserves"
    end
    
    it "should translate the loan period to a user friendly string" do
      @@new_val.split("-|-")[12].strip.should == "2 Hours"
    end
  end
  
  context "add_crez_info_to_solr_doc" do
    before(:each) do
      @@p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
      a = AddCrezToSolrDoc.new(@@p.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
      @@oldSid666 = a.solr_input_doc("666")
      @@newSid666 = a.add_crez_info_to_solr_doc("666")
      @@newSid555 = a.add_crez_info_to_solr_doc("555")
      p2 = ParseCrezData.new
      p2.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      b = AddCrezToSolrDoc.new(p2.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
      @@oldSid8707706 = b.solr_input_doc("8707706")
      @@newSid8707706 = b.add_crez_info_to_solr_doc("8707706")
      @@newSid9423045 = b.add_crez_info_to_solr_doc("9423045")
    end
    
    it "should add all the crez specific fields to the solr_input_doc for the ckey" do
      @@newSid666["crez_instructor_search"].getValues.should == java.util.ArrayList.new(["Saldivar, Jose David"])   
      @@newSid666["crez_course_name_search"].getValues.should == java.util.ArrayList.new(["What is Literature?"])
      @@newSid666["crez_course_id_search"].getValues.should == java.util.ArrayList.new(["COMPLIT-101"])
      @@newSid666["crez_desk_facet"].getValues.should == java.util.ArrayList.new(["Green Reserves"])
      @@newSid666["dept_facet"].getValues.should == java.util.ArrayList.new(["COMPLIT"])
      @@newSid666["crez_course_facet"].getValues.should == java.util.ArrayList.new(["COMPLIT-101 What is Literature?"])
      @@newSid666["crez_display"].getValues.should == java.util.ArrayList.new(["COMPLIT-101 -|- What is Literature? -|- Saldivar, Jose David"])
      
      @@newSid555["crez_instructor_search"].getValues.should == java.util.ArrayList.new(["Harris, Bradford Cole", "Kreiner, Jamie K"])
      @@newSid555["crez_course_name_search"].getValues.should  == java.util.ArrayList.new(["Saints in the Middle Ages"])
      @@newSid555["crez_course_id_search"].getValues.should == java.util.ArrayList.new(["HISTORY-41S", "HISTORY-211C"])
      @@newSid555["crez_desk_facet"].getValues.should == java.util.ArrayList.new(["Green Reserves"])
      @@newSid555["dept_facet"].getValues.should  == java.util.ArrayList.new(["HISTORY"])
      @@newSid555["crez_course_facet"].getValues.should  == java.util.ArrayList.new(["HISTORY-41S ", "HISTORY-211C Saints in the Middle Ages"])
      @@newSid555["crez_display"].getValues.should  == java.util.ArrayList.new(["HISTORY-41S -|-  -|- Harris, Bradford Cole", "HISTORY-211C -|- Saints in the Middle Ages -|- Kreiner, Jamie K"])
    end
    
    it "should call add_crez_val_to_access_facet once, always" do
      ac2sd = AddCrezToSolrDoc.new(@@p.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
      ac2sd.should_receive(:add_crez_val_to_access_facet).twice
      ac2sd.add_crez_info_to_solr_doc("8707706")
      ac2sd.add_crez_info_to_solr_doc("666")
    end
    
    it "should call update_building_facet once, always" do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      ac2sd = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
      ac2sd.should_receive(:update_building_facet).twice
      ac2sd.add_crez_info_to_solr_doc("8707706")
      ac2sd.add_crez_info_to_solr_doc("9423045")
    end
    
    it "should call append_crez_info_to_item_disp for every csv row with a matching item" do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      ac2sd = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
      ac2sd.should_receive(:append_crez_info_to_item_disp).twice
      ac2sd.add_crez_info_to_solr_doc("8707706")
    end
    
    it "should leave other fields alone" do
      @@oldSid8707706["title_245_search"].getValues.should == @@newSid8707706["title_245_search"].getValues
    end
    
  end # context add_crez_info_to_solr_doc

  
end