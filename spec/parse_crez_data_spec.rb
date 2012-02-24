#require File.expand_path('../spec_helper', __FILE__)
#require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require 'lib/parse_crez_data'


describe ParseCrezData do

  it "should implement read method" do
    ParseCrezData.new.read(File.expand_path('test_data/nonrezmiddle.csv', File.dirname(__FILE__)))
    puts "spec to be implemented"
  end
  
  describe "reading sirsi data file" do

# CSV.read(File.expand_path('spec/test_data/norezmiddle.csv', File.dirname(__FILE__))

    it "should read every line of the file" do
      pending
    end
    
    it "should assign the right values to the fields" do
      pending
    end
    
  end
  
  describe "extracting ckeys" do
    it "should ignore lines with item reserve status other than ON_RESERVE" do
      pending
    end
    
    it "should de-dup ckeys" do
      pending
    end
  end

  
end