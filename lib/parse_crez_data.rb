# FIXME:  module?  class?

require 'csv' 
#require 'ostruct'

class ParseCrezData
  
#  attr :sirsi_data
  
#  @csv_cols = "rez_desk|resctl_exp_date|resctl_status|ckey|barcode|home_loc|curr_loc|item_rez_status|loan_period|rez_expire_date|rez_stage|course_id|course_name|term|instructor_lib_id|instructor_univ_id|instructor_name"
  
  
#  MUSIC-RESV|20120109|CURRENT|555|36105041861316  |SCORES|MUSIC-RESV|ON_RESERVE|4H|20120109|ACTIVE|MUSIC-122C||FAL-WIN-SP|2000171265|09780727|Ferneyhough, Brian|
  
  
  # from parsing, want:
  #   ckey =>  array of on-rez items
  #     each item has all the stuff from the line
  
  attr :ckey_to_item_crez_info
  
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def read(csv_file_path)
    
    CSV.foreach(File.expand_path(csv_file_path, File.dirname(__FILE__)), {:col_sep => '|'}) do |row|
#      puts row
#      puts row[0]
      ckey = row[3]
      puts ckey

#    CSV.new(:headers => @csv_cols, :header_converters => :symbol)
      # row is an Array of fields
      
      # ignore if item reserve status isn't ON_RESERVE
      # 
      # otherwise, make a struct with all the relevant data and put it in the hash
      # use row here...
    end
  end
  
end