require 'solrmarc_wrapper'
require 'solrj_wrapper'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  
  attr_reader :ckey_2_crez_info, :new_solr_flds
  
  def initialize(solrmarc_dir, ckey_2_crez_info)
    @solrmarc_wrapper = SolrmarcWrapper.new(solrmarc_dir, "sw_config.properties")
    @solrj_wrapper = SolrjWrapper.new(solrmarc_dir + "lib")
    @ckey_2_crez_info = ckey_2_crez_info
    @new_solr_flds = {}
  end

  # given a ckey, 
  #  1. calls solrmarc_wrapper to retrieve a SolrInputDoc derived from the marcxml in the Solr index
  #  2. gets the relevant course reserve data from the reserves-dump .csv file
  #  3. adds the course reserve info to teh SolrInputDoc
  # @param ckey the id of the existing Document in the Solr index
  def add_crez_info_to_solr_doc(ckey)
    "to be implemented"
  end

  # retrieves the full marc record stored in the Solr index, runs it through SolrMarc indexing to get a SolrInputDocument
  #  note that it identifies Solr documents by the "id" field, and expects the marc to be stored in a Solr field "marcxml"
  # @param ckey  the value of the "id" Solr field for the record to be retrieved
  def solr_input_doc(ckey)
     @solrmarc_wrapper.get_solr_input_doc(ckey)
     # note:  @solrmarc_wrapper raises an exception if the ckey doesn't find a doc in the Solr index
  end

  # populates (and returns) crez_info with the Array of CSV::Row objects from the reserves data that pertain to the ckey
  def crez_info(ckey)
    @ckey_2_crez_info[ckey]
  end
  
  # given the csv rows to use, create a hash of new fields to add to the existing Solr doc.  keys are Solr field names, values are an array of values for the Solr field.
  # @param crez_rows the relevant rows from the course reserve csv file
  def create_new_solr_flds_hash(crez_rows)
    @new_solr_flds = {}
    crez_rows.each { |row|
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
  
  # add a value to the @new_solr_flds hash for the Solr field name.
  # @param solr_fldname_sym - the name of the new Solr field, as a symbol
  # @param new_val - the single value to add to the Solr field value array, if it isn't already there.
  def add_to_new_flds_hash(solr_fldname_sym, new_val)
    unless new_val.nil?
      @new_solr_flds[solr_fldname_sym] ||= []
      @new_solr_flds[solr_fldname_sym] << new_val
      @new_solr_flds[solr_fldname_sym].uniq!
    end
  end

  # given an array of existing values (can be nil), add the value from the indicated crez_info column to the array
  # @param crez_col_syms an Array of header symbols for the csv_row, in the order desired
  # @param sep the separator between the values
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
  
  # derive the department from the course_id
  def get_dept(course_id)
    dept = course_id.split("-")[0]
    dept = dept.split(" ")[0]
  end

  # add a value "Course Reserve" to the access_facet field of the solr_input_doc
  # @param solr_input_doc - the SolrInputDocument to be changed
  def add_crez_val_to_access_facet(solr_input_doc)
    @solrj_wrapper.add_vals_to_fld(solr_input_doc, "access_facet", ["Course Reserve"])
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def adjust_building_facet(solr_input_doc, crez_info)
    orig_build_facet_vals = solr_input_doc["building_facet"].getValues
    new_building_facet_vals ||= begin
      new_building_facet_vals = {}
      crez_info.each { |crez_row|  
        rez_desk = crez_row[]
            # for each item in crez with a rez-desk that doesn't map to nil
            #   if the rez-desk is different from the existing building
        # only do this once for all crez data
            #      recompute the whole building_facet, and use rez_desk instead of originating library
      }

    end
    
    
  end
  

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def modify_existing_fields
#    :item_display for the specific barcode modified   add  :rez_desk, :crez_callnum, :crez_loan_period, :crez_id
# :access facet gets additional value of "Course Reserve"
# :location facet changes per crez desk ... ewwwww
    
  end
  
end