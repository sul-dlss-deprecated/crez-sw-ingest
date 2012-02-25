require 'parse_crez_data.rb'

describe ParseCrezData do

  it "should ignore lines with item reserve status other than ON_RESERVE" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezfirst.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezmiddle.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezlast.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 2
  end
    
  it "should result in a Hash where key is ckey and value is an array of item crez info as field=>value hashes" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/crez1line.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.should be_a_kind_of(Hash)
    crez_info = p.ckey_2_crez_info["444"]
    crez_info.should be_an_instance_of(Array)
    crez_info.first.should be_an_instance_of(CSV::Row)
  end

  it "should have the correct field values for item crez info (i.e. correct header info)" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/crez1line.csv', File.dirname(__FILE__)))
    crez_item_info = p.ckey_2_crez_info["444"].first
    crez_item_info[:rez_desk].should == "GREEN-RESV"
    crez_item_info[:resctl_exp_date].should == "20111216"
    crez_item_info[:resctl_status].should == "CURRENT"
    crez_item_info[:ckey].should == "444"
    crez_item_info[:barcode].should == "36105005411207  "   # note that trimming whitespace will happen when the structure is used
    crez_item_info[:home_loc].should == "STACKS"
    crez_item_info[:curr_loc].should == "GREEN-RESV"
    crez_item_info[:item_rez_status].should == "ON_RESERVE"
    crez_item_info[:loan_period].should == "1DND-RES"
    crez_item_info[:rez_expire_date].should == "20111216"
    crez_item_info[:rez_stage].should == "ACTIVE"
    crez_item_info[:course_id].should == "HISTORY-211C"
    crez_item_info[:course_name].should == "Saints in the Middle Ages"
    crez_item_info[:term].should == "FALL"
    crez_item_info[:instructor_lib_id].should == "2556820237"
    crez_item_info[:instructor_univ_id].should == "05173979"
    crez_item_info[:instructor_name].should == "Kreiner, Jamie K"
  end
  
  it "should create an array value for each line of data with the same ckey" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multfirst.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 3
    p.ckey_2_crez_info["111"].size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmid.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 3
    p.ckey_2_crez_info["222"].size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multlast.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 3
    p.ckey_2_crez_info["333"].size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    p.ckey_2_crez_info.keys.size.should == 6
    p.ckey_2_crez_info["111"].size.should == 2
    p.ckey_2_crez_info["333"].size.should == 2
    p.ckey_2_crez_info["555"].size.should == 2
    p.ckey_2_crez_info["666"].size.should == 3
  end
  
end