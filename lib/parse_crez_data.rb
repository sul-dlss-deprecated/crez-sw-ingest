require 'csv'
require 'logger'

# Read a CSV file containing Course Reserve data dumped from Sirsi, per spec here:
#   https://consul.stanford.edu/display/NGDE/Symphony+Course+Reserves+Data+spec
#  and create a Hash with all the information
class ParseCrezData
  
  # hash: ckey => array of on-reserve items, each a CSV::Row object
  attr_accessor :ckey_2_crez_info

  @@csv_cols = "rez_desk|resctl_exp_date|resctl_status|ckey|barcode|home_loc|curr_loc|item_rez_status|loan_period|rez_expire_date|rez_stage|course_id|course_name|term|instructor_name"
  
  def initialize
# FIXME:  need to log to a file, passed in
    @logger = Logger.new(STDERR)
    @ckey_2_crez_info ||= {}
  end
  
  # read the csv file and populate @ckey_2_crez_info
  def read(csv_file_path)
    # re :quote_char - setting it to something other than "
    #   see http://stackoverflow.com/questions/8073920/importing-csv-ruby-1-9-2-quoting-error-driving-me-nuts 
    csv_options = {:col_sep => '|', :headers => @@csv_cols, :header_converters => :symbol, :quote_char => "\x00"}
    
    File.open(csv_file_path, 'r').each do |line|
      begin
        CSV.parse(line, csv_options) do |row|
          if row[:item_rez_status] == "ON_RESERVE"
            ckey = row[:ckey]
            crez_value = @ckey_2_crez_info[ckey] || []
            @ckey_2_crez_info[ckey] = crez_value << row
          end
        end
      rescue CSV::MalformedCSVError => e
        @logger.error("CSV::MalformedCSVError while parsing #{csv_file_path} -- #{e.message} -- #{line}")
        next
      end
    end
  end
  
end 