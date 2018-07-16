require 'spec_helper'
require 'parse_crez_data.rb'

describe ParseCrezData do

  it "should ignore lines with item reserve status other than ON_RESERVE" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezfirst.csv', File.dirname(__FILE__)))
    expect(p.ckey_2_crez_info.keys.size).to eq(2)
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezmiddle.csv', File.dirname(__FILE__)))
    expect(p.ckey_2_crez_info.keys.size).to eq(2)
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/nonrezlast.csv', File.dirname(__FILE__)))
    expect(p.ckey_2_crez_info.keys.size).to eq(2)
  end

  it "should result in a Hash where key is ckey and value is an array of item crez info as field=>value hashes" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/crez1line.csv', File.dirname(__FILE__)))
    expect(p.ckey_2_crez_info).to be_a_kind_of(Hash)
    crez_info = p.ckey_2_crez_info["444"]
    expect(crez_info).to be_an_instance_of(Array)
    expect(crez_info.first).to be_an_instance_of(CSV::Row)
  end

  it "should have the correct field values for item crez info (i.e. correct header info)" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/crez1line.csv', File.dirname(__FILE__)))
    crez_item_info = p.ckey_2_crez_info["444"].first
    expect(crez_item_info[:rez_desk]).to eq("GREEN-RESV")
    expect(crez_item_info[:resctl_exp_date]).to eq("20111216")
    expect(crez_item_info[:resctl_status]).to eq("CURRENT")
    expect(crez_item_info[:ckey]).to eq("444")
    expect(crez_item_info[:barcode]).to eq("36105005411207  ")   # note that trimming whitespace will happen when the structure is used
    expect(crez_item_info[:home_loc]).to eq("STACKS")
    expect(crez_item_info[:curr_loc]).to eq("GREEN-RESV")
    expect(crez_item_info[:item_rez_status]).to eq("ON_RESERVE")
    expect(crez_item_info[:loan_period]).to eq("1DND-RES")
    expect(crez_item_info[:rez_expire_date]).to eq("20111216")
    expect(crez_item_info[:rez_stage]).to eq("ACTIVE")
    expect(crez_item_info[:course_id]).to eq("HISTORY-211C")
    expect(crez_item_info[:course_name]).to eq("Saints in the Middle Ages")
    expect(crez_item_info[:term]).to eq("FALL")
    expect(crez_item_info[:instructor_lib_id]).to eq(nil)
    expect(crez_item_info[:instructor_univ_id]).to eq(nil)
    expect(crez_item_info[:instructor_name]).to eq("Kreiner, Jamie K")
  end

  it "should create an array value for each line of data with the same ckey" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multfirst.csv', File.dirname(__FILE__)))
    result_hash = p.ckey_2_crez_info
    expect(result_hash.keys.size).to eq(3)
    expect(result_hash["111"].size).to eq(2)
    expect(result_hash["111"].first[:resctl_exp_date]).to eq("20111216")
    expect(result_hash["111"].last[:resctl_exp_date]).to eq("20111217")
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmid.csv', File.dirname(__FILE__)))
    result_hash = p.ckey_2_crez_info
    expect(result_hash.keys.size).to eq(3)
    expect(result_hash["222"].size).to eq(2)
    expect(result_hash["222"].first[:term]).to eq("FALL")
    expect(result_hash["222"].last[:term]).to eq("SPRING")
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multlast.csv', File.dirname(__FILE__)))
    result_hash = p.ckey_2_crez_info
    expect(result_hash.keys.size).to eq(3)
    expect(result_hash["333"].size).to eq(2)
    expect(result_hash["333"].first[:rez_desk]).to eq("GREEN-RESV")
    expect(result_hash["333"].last[:rez_desk]).to eq("ART-RESV")
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multmult.csv', File.dirname(__FILE__)))
    result_hash = p.ckey_2_crez_info
    expect(result_hash.keys.size).to eq(6)
    expect(result_hash["111"].size).to eq(2)
    expect(result_hash["333"].size).to eq(2)
    expect(result_hash["555"].size).to eq(2)
    expect(result_hash["666"].size).to eq(3)
  end

  it "should set nil value to missing fields" do
    p = ParseCrezData.new
    p.read(File.expand_path('test_data/multlast.csv', File.dirname(__FILE__)))
    result_hash = p.ckey_2_crez_info
    expect(result_hash.keys.size).to eq(3)
    expect(result_hash["333"].size).to eq(2)
    expect(p.ckey_2_crez_info["111"].first[:course_name]).to eq(nil)
  end

end
