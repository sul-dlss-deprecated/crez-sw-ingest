require 'parse_crez_data.rb'

describe ParseCrezData do

  it "should ignore lines with item reserve status other than ON_RESERVE" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezfirst.csv', File.dirname(__FILE__)))
    p.ckey_2_item_crez_info.keys.size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezmiddle.csv', File.dirname(__FILE__)))
    p.ckey_2_item_crez_info.keys.size.should == 2
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezlast.csv', File.dirname(__FILE__)))
    p.ckey_2_item_crez_info.keys.size.should == 2
  end
    
  it "should result in a Hash where key is ckey and value is an array of item crez info as field=>value hashes" do
    pending "not implemented yet"
  end
  
  it "should read every line of the file" do
    pending "not implemented yet"
  end
    
  it "should assign the right values to the fields" do
    pending "not implemented yet"
  end
  
  it "should handle multiple entries with same ckey" do
    pending "not implemented yet"
  end
  
end