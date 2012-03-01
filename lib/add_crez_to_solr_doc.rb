require 'get_solrdoc_from_solrmarc'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  
  attr_reader :ckey_2_crez_info, :new_solr_flds
  
  def initialize(solrmarc_dir, ckey_2_crez_info)
    @get_solr_doc_from_solrmarc = GetSolrdocFromSolrmarc.new(solrmarc_dir, "sw_config.properties")
    @ckey_2_crez_info = ckey_2_crez_info
    @new_solr_flds = {}
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def solr_input_doc(ckey)
     @solr_input_doc = @get_solr_doc_from_solrmarc.get_solr_input_doc(ckey)
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def crez_info(ckey)
    @crez_info = @ckey_2_crez_info[ckey]
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def create_new_solr_flds_hash(ckey)
    @new_solr_flds = {}
    crez_info(ckey).each { |row|
      add_to_new_flds_hash(:crez_instructor_search, row[:instructor_name])
      add_to_new_flds_hash(:crez_course_name_search, row[:course_name])
      add_to_new_flds_hash(:crez_course_id_search, row[:course_id])
# instructor facet is a copy field
      add_to_new_flds_hash(:crez_term_facet, row[:term])
      add_to_new_flds_hash(:crez_desk_facet, row[:rez_desk])
      add_to_new_flds_hash(:dept_facet, get_dept(row[:course_id]))
      add_to_new_flds_hash(:crez_course_facet, get_compound_value_from_row(row, [:course_id, :term], " ")) # section info unavail
      add_to_new_flds_hash(:crez_course_w_name_facet, get_compound_value_from_row(row, [:course_id, :term, :course_name], " ")) # for record view
      add_to_new_flds_hash(:crez_display, get_compound_value_from_row(row, [:course_id, :course_name, :instructor_name, :term], " -|- "))
    }
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def add_to_new_flds_hash(solr_fldname_sym, new_val)
    unless new_val.nil?
      @new_solr_flds[solr_fldname_sym] ||= []
      @new_solr_flds[solr_fldname_sym] << new_val
      @new_solr_flds[solr_fldname_sym].uniq!
    end
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  # given an array of existing values (can be nil), add the value from the indicated crez_info column to the array
  # @crez_col_syms an Array of header symbols for the csv_row, in the order desired
  # @sep the separator between the values
  def get_compound_value_from_row(csv_row, crez_col_syms, sep)
    compound_val = nil
    crez_col_syms.each { |col|
      col_val = csv_row[col].to_s.dup # CSV::Row is adding a space for multiple lookups - odd
      if compound_val.nil?
        compound_val = col_val
      else
        compound_val << sep << col_val
      end
    }
    compound_val
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def get_dept(course_id)
    dept = course_id.split("-")[0]
    dept = dept.split(" ")[0]
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def modify_existing_fields
#    :item_display for the specific barcode modified   add  :rez_desk, :crez_callnum, :crez_loan_period, :crez_id
# :access facet gets additional value of "Course Reserve"
# :location facet changes per crez desk ... ewwwww
    
  end
  
=begin  
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
=end  
  
  
  
end