require 'solrmarc_wrapper'
require 'solrj_wrapper'
require 'rez_desk_translations'
require 'library_code_translations'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  include RezDeskTranslations
  include LibraryCodeTranslations
  
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
  #  3. adds the course reserve info to the SolrInputDoc
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
      add_to_new_flds_hash(:crez_desk_facet, REZ_DESK_2_REZ_LOC_FACET[row[:rez_desk]])
      add_to_new_flds_hash(:dept_facet, get_dept(row[:course_id]))
      add_to_new_flds_hash(:crez_course_facet, get_compound_value_from_row(row, [:course_id, :course_name], " ")) # for record view
      add_to_new_flds_hash(:crez_display, get_compound_value_from_row(row, [:course_id, :course_name, :instructor_name], " -|- "))
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
      new_building_facet_vals = []
      crez_info.each { |crez_row|
        #  do we need to recompute the building facet?
        rez_building = REZ_DESK_2_BLDG_FACET[crez_row[:rez_desk]]
        unless rez_building.nil? 
          crez_barcode = crez_row[:barcode]
          item_disp_val = get_item_display_val(crez_barcode, solr_input_doc)
          item_disp_hash = item_disp_val_hash(item_disp_val)
          if rez_building != item_disp_hash[:building]
              # if the rez-desk is different from the existing building
              need_to_redo_bldg_facet = true
          # only do this once for all crez data
              #      recompute the whole building_facet, and use rez_desk instead of originating library
          end
        end
      }
      if need_to_redo_bldg_facet
        redo_building_facet(solr_input_doc, creaz_info)
      end
    end
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def redo_building_facet(solr_input_doc, crez_info)
    new_building_facet_vals = []
    item_display_vals = solr_input_doc["item_display"].getValues
    item_display_vals.each { |idv|
      idv_hash = item_disp_val_hash(idv)
      matching_rows = []
      matching_rows = crez_info.select { |crez_row|  
        crez_row[:barcode].strip == idv_hash[:barcode] }
      if matching_rows.size == 1
        new_building_facet_vals << REZ_DESK_2_BLDG_FACET[matching_rows[0][:rez_desk]]
      else
        new_building_facet_vals << LIB_2_BLDG_FACET[idv_hash[:building]]
      end
    }
    solr_input_doc.removeField("building_facet")
    @solrj_wrapper.add_vals_to_fld(solr_input_doc, "building_facet", new_building_facet_vals.uniq)
  end
  
  # @param desired_barcode the barcode of the desired item_display field
  # @param solr_input_doc the SolrInputDocument with item_display fields to be matched
  # @return the single item display field matching the barcode, or nil if none match
  def get_item_display_val(desired_barcode, solr_input_doc)
    item_display_vals = solr_input_doc["item_display"].getValues
    array_result = item_display_vals.find { |idv|
      desired_barcode == item_disp_val_hash(idv)[:barcode]
    }
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def item_disp_val_hash(item_display_val)
    idv_array = item_display_val.split("-|-").map{|w| w.strip }
    { 
      :barcode => idv_array[0],
      :building => idv_array[1]
#      :home_location => idv_array[2],
#      :current_location => idv_array[3],
#      :callnum_type => idv_array[4],
#      :trunc_callnum => idv_array[5],
#      :trunc_shelfkey => idv_array[6],
#      :reverse_shelfkey => idv_array[7],
#      :full_callnum => idv_array[8],
#      :full_shelfkey => idv_array[9]
    }
  end
  

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def modify_existing_fields
#    :item_display for the specific barcode modified   add  :rez_desk, :crez_callnum, :crez_loan_period, :crez_id
# :access facet gets additional value of "Course Reserve"
# :location facet changes per crez desk ... ewwwww
    
  end
  
end