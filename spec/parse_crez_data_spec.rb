require 'parse_crez_data.rb'

describe ParseCrezData do

  it "should implement read method" do
    ParseCrezData.new.read(File.expand_path('test_data/nonrezmiddle.csv', File.dirname(__FILE__)))
  end
  
  describe "reading sirsi data file" do

# CSV.read(File.expand_path('spec/test_data/norezmiddle.csv', File.dirname(__FILE__))

    it "should read every line of the file" do
      pending "not implemented"
    end
    
    it "should assign the right values to the fields" do
      pending "not implemented"
    end
    
  end
  
  describe "extracting ckeys" do
    it "should ignore lines with item reserve status other than ON_RESERVE" do
      pending "not implemented"
    end
    
    it "should de-dup ckeys" do
      pending "not implemented"
    end
  end

  
end