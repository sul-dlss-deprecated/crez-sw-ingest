require 'get_solrdoc_from_solrmarc'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  
  attr_reader :ckey_2_crez_info
  
  def initialize(solrmarc_dir, ckey_2_crez_info)
    @get_solr_doc_from_solrmarc = GetSolrdocFromSolrmarc.new(solrmarc_dir, "sw_config.properties")
    @ckey_2_crez_info = ckey_2_crez_info
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
  def new_solr_flds_hash
    new_flds_hash = {}
    
    @crez_info.each { |row|
      # simple fields
      new_flds_hash[:crez_instructor_search] = add_vals_from_row(new_flds_hash[:instructor_search], row, :instructor_name)
      new_flds_hash[:crez_term_search] = add_vals_from_row(new_flds_hash[:term_search], row, :term)
      new_flds_hash[:crez_course_name_search] = add_vals_from_row(new_flds_hash[:crez_course_name_search], row, :course_name)
      new_flds_hash[:crez_course_id_search] = add_vals_from_row(new_flds_hash[:crez_course_id_search], row, :course_id)
      new_flds_hash[:crez_course_facet] = add_vals_from_row(new_flds_hash[:crez_course_id_search], row, :course_id)
      new_flds_hash[:crez_desk] = add_vals_from_row(new_flds_hash[:crez_desk], row, :rez_desk)
# instructor facet is a copy field
      # compound value fields
=begin       
      :course_id_facet(number + section + term)
      :course_facet (number + term + section + title)
      :crez_display  (course_id, course_title, instructor, (term?))
=end
    }
    
    # department - derive from course id
  end
  
  # given an array of existing values (can be nil), add the value from the indicated crez_info column to the array
  def add_val_from_row(vals, csv_row, crez_col_sym)
    vals ||= []
    vals << csv_row[crez_col_sym] unless csv_row[crez_col_sym].nil?
    vals.uniq
  end
  
  # given an array of existing values (can be nil), add the value from the indicated crez_info column to the array
  def add_compound_val_from_row(vals, csv_row, crez_col_syms)
    
    vals ||= []
    vals << csv_row[crez_col_sym] unless csv_row[crez_col_sym].nil?
    vals.uniq
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def modify_item_display
#    :item_display for the specific barcode modified   add  :rez_desk, :crez_callnum, :crez_loan_period, :crez_id
# :access facet gets additional value of "Course Reserve"
    
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