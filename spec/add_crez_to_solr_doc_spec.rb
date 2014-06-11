require File.expand_path('../spec_helper', __FILE__)
require 'add_crez_to_solr_doc'
require 'parse_crez_data'
require 'logger'

describe AddCrezToSolrDoc do
  
  before(:all) do
    @solrmarc_wrapper = SolrmarcWrapper.new(@@settings.solrmarc_dist_dir, @@settings.solrmarc_conf_props_file, @@settings.solr_source_url)
    @solrj_wrapper = SolrjWrapper.new(@@settings.solrj_jar_dir, @@settings.solr_source_url)
    @p = ParseCrezData.new
    @p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    @ckey_2_crez_info = @p.ckey_2_crez_info
    @a = AddCrezToSolrDoc.new(@ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
    @sid555 = @a.solr_input_doc("555")
    @sid666 = @a.solr_input_doc("666")
  end

  it "should retrieve the solr_input_doc for a ckey" do
    expect(@sid666).not_to be(nil)
    expect(@sid666).to be_an_instance_of(Java::OrgApacheSolrCommon::SolrInputDocument)
    expect(@sid666["id"].getValue).to eq "666"
  end
  
  it "should retrieve the array of crez_info csv rows for a ckey" do
    crez_info = @a.crez_info("666")
    expect(crez_info).to be_an_instance_of(Array)
    expect(crez_info[0]).to be_an_instance_of(CSV::Row)
  end
  
  it "should log an error message when no item matches the barcode from Course Reserve data" do
    lager = double("logger")
    @a.logger = lager
    expect(lager).to receive(:error).with("Solr Document for 666 has no item with barcode 666")
    expect(lager).to receive(:error).with("Solr Document for 666 has no item with barcode 667")
    expect(lager).to receive(:error).with("Solr Document for 666 has no item with barcode 668")
    @a.add_crez_info_to_solr_doc("666")
  end
    
  it "should log an error message when there are no csv rows for a ckey" do
    lager = double("logger")
    @a.logger = lager
    expect(lager).to receive(:error).with("Ckey 777 has no rows in the Course Reserves csv data")
    @a.add_crez_info_to_solr_doc("777")
  end
  
  context "get_compound_value_from_row" do
    it "should add the fields in order, with the indicated separator" do
      row = @a.crez_info("666")[0]
      val = @a.get_compound_value_from_row(row, [:course_id, :term, :ckey], "|")
      expect(val).to eq("COMPLIT-101|FALL|666")
      val = @a.get_compound_value_from_row(row, [:course_id, :term, :ckey], " ")
      expect(val).to eq("COMPLIT-101 FALL 666")
      val = @a.get_compound_value_from_row(row, [:course_id, :ckey, :term], " -!- ")
      expect(val).to eq("COMPLIT-101 -!- 666 -!- FALL")
    end
    
    it "should use an empty string for a missing column" do
      row = @a.crez_info("666")[0]
      val = @a.get_compound_value_from_row(row, [:fake, :term], " ")
      expect(val).to eq(" FALL")
      val = @a.get_compound_value_from_row(row, [:term, :fake], " ")
      expect(val).to eq("FALL ")
      val = @a.get_compound_value_from_row(row, [:course_id, :fake, :term], " -|- ")
      expect(val).to eq("COMPLIT-101 -|-  -|- FALL")
    end
  end

  it "should set dept to the translated course id(s) before the slash" do
    expect(@a.get_dept("COMPLIT-101")).to eq("Comparative Literature")
    expect(@a.get_dept("MUSIC-2C-001")).to eq("Music")
    expect(@a.get_dept("GEOPHYS 251")).to eq("Geophysics")
    expect(@a.get_dept("BIOHOPK-182H/323H")).to eq("Biology/Hopkins Marine")
  end

  context "get_matching_item_from_doc" do
    it "should return nil if there is no matching barcode" do
      expect(@a.get_matching_item_from_doc("fake", @sid666)).to be(nil)
    end

    it "should find an item_display field with matching barcode" do
      matching_val = @a.get_matching_item_from_doc("36105041846424", @sid666)
      expect(matching_val.split("-|-").size).to be(10)
      expect(matching_val.split("-|-")[0].strip).to eq("36105041846424")
      sid = @a.solr_input_doc("9340596")
      matching_val = @a.get_matching_item_from_doc("36105217077085", sid)
      expect(matching_val.split("-|-").size).to be(10)
      expect(matching_val.split("-|-")[0].strip).to eq("36105217077085")
      matching_val = @a.get_matching_item_from_doc("36105217629935", sid)
      expect(matching_val.split("-|-").size).to be(10)
      expect(matching_val.split("-|-")[0].strip).to eq("36105217629935")
    end
  end
  
  context "redo_building_facet" do
    before(:all) do
      @p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      @ac2sd = AddCrezToSolrDoc.new(@ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
    end

    it "should use the Course Reserve rez_desk value instead of the item_display library value" do
      sid9262146 = @ac2sd.solr_input_doc("9262146")
      orig_vals = sid9262146["building_facet"].getValues
      expect(orig_vals.size).to be(2)
      expect(orig_vals).to include("Green")
      expect(orig_vals).to include("Art & Architecture")
      @ac2sd.redo_building_facet(sid9262146, @ac2sd.crez_info("9262146"))
      new_vals = sid9262146["building_facet"].getValues
      expect(new_vals.size).to be(2)
      expect(new_vals).to include("Engineering (Terman)")
      expect(new_vals).to include("Art & Architecture")
      
      sid8707706 = @ac2sd.solr_input_doc("8707706")
      orig_vals = sid8707706["building_facet"].getValues
      expect(orig_vals.size).to be(4)
      expect(orig_vals).to include("Green")
      expect(orig_vals).to include("Art & Architecture")
      expect(orig_vals).to include("Education (Cubberley)")
      @ac2sd.redo_building_facet(sid8707706, @ac2sd.crez_info("8707706"))
      new_vals = sid8707706["building_facet"].getValues
      expect(new_vals.size).to be(3)
      expect(new_vals).to include("Green")
      expect(new_vals).to include("Engineering (Terman)")
    end

    it "should retain the library loc if only some items with that loc are overridden" do
      sid8834492 = @ac2sd.solr_input_doc("8834492")
      orig_vals = sid8834492["building_facet"].getValues.to_a
      expect(orig_vals.size).to be(2)
      expect(orig_vals).to include("Green")
      expect(orig_vals).to include("SAL3 (off-campus storage)")
      @ac2sd.redo_building_facet(sid8834492, @ac2sd.crez_info("8834492"))
      new_vals = sid8834492["building_facet"].getValues
      expect(new_vals.size).to be(3)
      expect(orig_vals).to include("Green")
      expect(orig_vals).to include("SAL3 (off-campus storage)")
      expect(new_vals).to include("Engineering (Terman)")
    end
    
    it "should retain the library if the crez location is for the same library" do
      sid9423045 = @ac2sd.solr_input_doc("9423045")
      orig_vals = sid9423045["building_facet"].getValues
      expect(orig_vals.size).to be(1)
      expect(orig_vals[0]).to eq("Green")
      @ac2sd.redo_building_facet(sid9423045, @ac2sd.crez_info("9423045"))
      new_vals = sid9423045["building_facet"].getValues
      expect(new_vals.size).to be(1)
      expect(new_vals[0]).to eq("Green")
    end

    it "should ignore a crez loc with no translation (use the library from item_display)" do
      sid888 = @ac2sd.solr_input_doc("888")
      orig_vals = sid888["building_facet"].getValues
      expect(orig_vals.size).to be(1)
      expect(orig_vals[0]).to eq("Music")
      @ac2sd.redo_building_facet(sid888, @ac2sd.crez_info("888"))
      new_vals = sid888["building_facet"].getValues
      expect(new_vals.size).to be(1)
      expect(new_vals[0]).to eq("Music")
      # no translation for library in item_display either
      sid9434391 = @ac2sd.solr_input_doc("9434391")
      expect(sid9434391["building_facet"]).to be(nil)
      @ac2sd.redo_building_facet(sid9434391, @ac2sd.crez_info("9434391"))
      expect(sid9434391["building_facet"]).to be(nil)
    end
    
    it "should create a building_facet value from the crez loc when there was no original value from item_display" do
      sid9518589 = @ac2sd.solr_input_doc("9518589")
      expect(sid9518589["building_facet"]).to be(nil)
      @ac2sd.redo_building_facet(sid9518589, @ac2sd.crez_info("9518589"))
      new_vals = sid9518589["building_facet"].getValues
      expect(new_vals.size).to be(1)
      expect(new_vals[0]).to eq("Engineering (Terman)")
    end

#    it "should ignore a (un-overridden) library value missing from the library translation table" do
#      pending "need a record with both an overridden and an unoverridden case ..."
#    end
  end # context "redo_building_facet"

  context "update_building_facet" do
    before(:all) do
      @p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
    end
    
    it "should only call redo_building_facet once" do
      expect(@a).to receive(:redo_building_facet).once
      sid8707706 = @a.solr_input_doc("8707706")
      @a.update_building_facet(sid8707706, @a.crez_info("8707706"))
    end

    it "should call redo_building_facet if there is a rez desk and there was no building_facet value" do
      expect(@a).to receive(:redo_building_facet).once
      sid9518589 = @a.solr_input_doc("9518589")
      @a.update_building_facet(sid9518589, @a.crez_info("9518589"))
    end
    
    it "should not call redo_building_facet if no crez rez-desk differs from library in item_display field" do
      expect(@a).not_to receive(:redo_building_facet)
      sid4286782 = @a.solr_input_doc("4286782")
      @a.update_building_facet(sid4286782, @a.crez_info("4286782"))
    end
    
    it "should not call redo_building_facet if the only rez_desk values don't map to anything" do
      expect(@a).not_to receive(:redo_building_facet)
      sid9434391 = @a.solr_input_doc("9434391")
      @a.update_building_facet(sid9434391, @a.crez_info("9434391"))
    end
  end # context update_building_facet


  context "update_item_display" do
    before(:each) do
      @p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      @crez8834492_row0 = @p.ckey_2_crez_info["8834492"][0]
      @item_display_val = @sid666["item_display"].getValues.first
      @new_val = @a.update_item_display(@item_display_val, @crez8834492_row0)
    end
    
    it "should add the right number of separators to the item_display value" do
      expect(@item_display_val.split("-|-").size).to be(10)
      expect(@new_val.split("-|-").size).to be(13)
    end
    
    it "should change the current location to the rez desk" do
      expect(@new_val.split("-|-")[3].strip).to eq("ENG-RESV")
      old_val = "36105217655393 -|- SAL3 -|- STACKS -|- CHECKEDOUT -|- STKS-MONO -|- PQ8550.413 .E64 A615 2011 -|- lc pq  8550.413000 e0.640000 a0.615000 002011 -|- en~a9~~ruuz}vywzzz~lz}tvzzzz~pz}tyuzzz~zzxzyy~~~~~ -|- PQ8550.413 .E64 A615 2011 -|- lc pq  8550.413000 e0.640000 a0.615000 002011"
      expect(old_val.split("-|-")[3].strip).to eq("CHECKEDOUT")
      new_val = @a.update_item_display(old_val, @crez8834492_row0)
      expect(new_val.split("-|-")[3].strip).to eq("ENG-RESV")
    end
    
    it "should keep the right number of pieces in the original field, if they are empty" do
      old_val = "5761709-3001 -|- SUL -|- INSTRUCTOR -|- ENG-RESV -|- NH-RESERVS -|-  -|-  -|-  -|-  -|- "
      new_val = @a.update_item_display(old_val, @crez8834492_row0)
      expect(new_val).to start_with(old_val)
      old_val2 = "5761709-3001 -|- SUL -|- INSTRUCTOR -|-  -|- NH-RESERVS -|-  -|-  -|-  -|-  -|- "
      new_val = @a.update_item_display(old_val2, @crez8834492_row0)
      expect(new_val).to start_with(old_val)
      old_val3 = "5761709-3001 -|-  -|-  -|-  -|- NH-RESERVS -|-  -|-  -|-  -|-  -|- "
      new_val = @a.update_item_display(old_val3, @crez8834492_row0)
      expect(new_val).to start_with("5761709-3001 -|-  -|-  -|- ENG-RESV -|- NH-RESERVS -|-  -|-  -|-  -|-  -|- ")
    end
    
    it "should append course id, rez_desk and loan period to the item_display value" do
      idv = @item_display_val.split(' -|- ')
      idv[3] = "ENG-RESV"
      expect(@new_val).to eq(idv.join(' -|- ') + " -|- COMPLIT-101 -|- ENG-RESV -|- 2-hour loan")
    end

    it "should not translate the rez desk to a user friendly string" do
      expect(@new_val.split("-|-")[11].strip).to eq("ENG-RESV")
    end
    
    it "should translate the loan period to a user friendly string" do
      expect(@new_val.split("-|-")[12].strip).to eq("2-hour loan")
    end
    
  end
  
  context "add_crez_info_to_solr_doc" do
    before(:each) do
      @p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
      a = AddCrezToSolrDoc.new(@p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      @oldSid666 = a.solr_input_doc("666")
      @newSid666 = a.add_crez_info_to_solr_doc("666")
      @newSid555 = a.add_crez_info_to_solr_doc("555")
      p2 = ParseCrezData.new
      p2.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      b = AddCrezToSolrDoc.new(p2.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      @oldSid8707706 = b.solr_input_doc("8707706")
      @newSid8707706 = b.add_crez_info_to_solr_doc("8707706")
      @newSid9423045 = b.add_crez_info_to_solr_doc("9423045")
    end
    
    it "should add all the crez specific fields to the solr_input_doc for the ckey" do
      expect(@newSid666["crez_instructor_search"].getValues).to eq(java.util.ArrayList.new(["Saldivar, Jose David"]))
      expect(@newSid666["crez_course_name_search"].getValues).to eq(java.util.ArrayList.new(["What is Literature?"]))
      expect(@newSid666["crez_course_id_search"].getValues).to eq(java.util.ArrayList.new(["COMPLIT-101"]))
      expect(@newSid666["crez_desk_facet"].getValues).to eq(java.util.ArrayList.new(["Green Reserves"]))
      expect(@newSid666["crez_dept_facet"].getValues).to eq(java.util.ArrayList.new(["Comparative Literature"]))
      expect(@newSid666["crez_course_info"].getValues).to eq(java.util.ArrayList.new(["COMPLIT-101 -|- What is Literature? -|- Saldivar, Jose David"]))
      
      expect(@newSid555["crez_instructor_search"].getValues).to eq(java.util.ArrayList.new(["Harris, Bradford Cole", "Kreiner, Jamie K"]))
      expect(@newSid555["crez_course_name_search"].getValues).to eq(java.util.ArrayList.new(["Saints in the Middle Ages"]))
      expect(@newSid555["crez_course_id_search"].getValues).to eq(java.util.ArrayList.new(["HISTORY-41S", "HISTORY-211C"]))
      expect(@newSid555["crez_desk_facet"].getValues).to eq(java.util.ArrayList.new(["Green Reserves"]))
      expect(@newSid555["crez_dept_facet"].getValues).to eq(java.util.ArrayList.new(["History"]))
      expect(@newSid555["crez_course_info"].getValues).to eq(java.util.ArrayList.new(["HISTORY-41S -|-  -|- Harris, Bradford Cole", "HISTORY-211C -|- Saints in the Middle Ages -|- Kreiner, Jamie K"]))
    end
    
    it "should not call add_crez_val_to_access_facet" do
      ac2sd = AddCrezToSolrDoc.new(@p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      expect(ac2sd).not_to receive(:add_crez_val_to_access_facet)
      ac2sd.add_crez_info_to_solr_doc("8707706")
      ac2sd.add_crez_info_to_solr_doc("666")
    end
    
    it "should call update_building_facet once, always" do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      ac2sd = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      expect(ac2sd).to receive(:update_building_facet).twice
      ac2sd.add_crez_info_to_solr_doc("8707706")
      ac2sd.add_crez_info_to_solr_doc("9423045")
    end
    
    it "should overwrite the existing item_display field for the barcode" do
      @p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      expect(@sid666["item_display"].getValues.size).to be(1)
      ac2sd = AddCrezToSolrDoc.new(@p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      @oldSid8707706 = ac2sd.solr_input_doc("8707706")
      @newSid8707706 = ac2sd.add_crez_info_to_solr_doc("8707706")
      expect(@newSid8707706["item_display"].getValues.size).to be(@oldSid8707706["item_display"].getValues.size)
    end
    
    it "should call update_item_display for every csv row with a matching item" do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__)))
      ac2sd = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
      expect(ac2sd).to receive(:update_item_display).twice
      ac2sd.add_crez_info_to_solr_doc("8707706")
    end
    
    it "should leave other fields alone" do
      expect(@oldSid8707706["title_245_search"].getValues).to eq(@newSid8707706["title_245_search"].getValues)
    end
    
  end # context add_crez_info_to_solr_doc

  
end
