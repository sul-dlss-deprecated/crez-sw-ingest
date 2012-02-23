#require File.expand_path('../spec_helper', __FILE__)
# FIXME:  should not be "load" I imagine
load 'lib/parse_crez_data.rb'

describe ParseCrezData do

  it "should implement read method" do
    ParseCrezData.new.read_it
    puts "spec to be implemented"
  end
  
end