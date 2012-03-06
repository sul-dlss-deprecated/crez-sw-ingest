require 'solrmarc_wrapper'
require 'solrj_wrapper'
require 'rez_desk_translations'
require 'library_code_translations'
require 'loan_period_translations'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  include RezDeskTranslations
  include LibraryCodeTranslations
  include LoanPeriodTranslations
  
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
    sid = solr_input_doc(ckey)
    crez_rows = crez_info(ckey)
# FIXME:  it would be more efficient to loop through crez rows here and do what needs doing for each row in other methods    
    
# createNew_solr_flds_hash(crez_rows)
#  write hash to doc    

    crez_rows.each { |crez_row|
      orig_item_disp_val = get_matching_item_from_doc(crez_row[:barcode], solr_input_doc)
      new_item_disp_val = append_crez_info_to_item_disp(orig_item_disp_val, crez_row)
      # write new item disp val
    }

    add_crez_val_to_access_facet(sid)
    update_building_facet(sid, crez_rows)
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
  
  # add a value "Course Reserve" to the access_facet field of the solr_input_doc
  # @param solr_input_doc - the SolrInputDocument to be changed
  def add_crez_val_to_access_facet(solr_input_doc)
    @solrj_wrapper.add_vals_to_fld(solr_input_doc, "access_facet", ["Course Reserve"])
  end
  
  # Recompute the building_facet values but ONLY *if needed* -- when there is a rez_desk value
  #  that warrants it (by differing from the home library of an item)
  # @param solr_input_doc the SolrInputDocument object that will get new building_facet values
  # @param crez_info an Array of CSV::Row objects containing data for items in the SolrInputDocument
  def update_building_facet(solr_input_doc, crez_info)
    crez_info.each { |crez_row|
      #  do we need to recompute the building facet?
      rez_building = REZ_DESK_2_BLDG_FACET[crez_row[:rez_desk]]
      unless rez_building.nil? 
        item_disp_val = get_matching_item_from_doc(crez_row[:barcode], solr_input_doc)
        item_disp_hash = item_disp_val_hash(item_disp_val)
        if rez_building != LIB_2_BLDG_FACET[item_disp_hash[:building]]
            # the rez-desk is different from the existing building so we must redo the facet values
            redo_building_facet(solr_input_doc, crez_info)
            return
        end
      end
    }
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def update_item_display_fields(solr_input_doc, crez_info)
    # for each crez row that matches an item display value
    #   update that item_display value
    #   leave all the other ones alone.
    item_display_vals = solr_input_doc["item_display"].getValues
    crez_info.each { |crez_row|  
      update_item_display_field(solr_input_doc, crez_row)
      orig_item_disp_val = get_matching_item_from_vals(crez_row[:barcode], item_display_vals)
      ix = item_display_vals.index(orig_item_disp_val)
      if ix >= 0
        item_display_vals[ix] = add_crez_info_to_item_disp_val(orig_item_disp_val, crez_row)
      else
        # FIXME: this should print an error message??  or someplace else doing this matching ...
        item_display_vals << add_crez_info_to_item_disp_val(orig_item_disp_val, crez_row)
      end
    }

# FIXME:  need solrj_wrapper method for  replace_all_field_vals    
#   want to only do this if the array changed
    if item_display_vals.size > 0 && item_display_vals != [nil]
      solr_input_doc.removeField("item_display")
      @solrj_wrapper.add_vals_to_fld(solr_input_doc, "item_display", item_display_vals)
    end
  end
  
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  # Note: there is no checking here to ensure the crez_row barcode matches the item_display barcode
  def append_crez_info_to_item_disp(orig_item_display_val, crez_row)
    sep = " -|- "
    rez_building = REZ_DESK_2_REZ_LOC_FACET[crez_row[:rez_desk]]
    loan_period = LOAN_CODE_2_USER_STR[crez_row[:loan_period]]
    suffix = crez_row[:course_id] + sep + rez_building + sep + loan_period
    orig_item_display_val + " -|- " + suffix
  end

# ---------------- FIXME:  probably should be protected ---------------------------

  # derive the department from the course_id
  def get_dept(course_id)
    dept = course_id.split("-")[0]
    dept = dept.split(" ")[0]
  end

# FIXME: this method should go away
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

# FIXME: this method should probably go away  
  # @param desired_barcode the barcode of the desired item_display field
  # @param solr_input_doc the SolrInputDocument with item_display fields to be matched
  # @return the single item display field matching the barcode, or nil if none match
  def get_matching_item_from_doc(desired_barcode, solr_input_doc)
    item_display_vals = solr_input_doc["item_display"].getValues
    get_matching_item_from_values(desired_barcode, item_display_vals)
  end

  # NOTE:  use adjust_building_facet unless you are sure you need to recompute the values
  # recompute the values for the building_facet for a document based on crez data and item_display data
  #  the passed solr_input_doc is changed by this method
  # @param solr_input_doc the SolrInputDocument object that will get new building_facet values
  # @param crez_info an Array of CSV::Row objects containing data for items in the SolrInputDocument
  def redo_building_facet(solr_input_doc, crez_info)
    new_building_facet_vals = []
    item_display_vals = solr_input_doc["item_display"].getValues
    item_display_vals.each { |idv|
      idv_hash = item_disp_val_hash(idv)
      matching_rows = []
      matching_rows = crez_info.select { |crez_row|  
        crez_row[:barcode].strip == idv_hash[:barcode] 
      }
      home_bldg = LIB_2_BLDG_FACET[idv_hash[:building]]
      if matching_rows.size == 1
        rez_building = REZ_DESK_2_BLDG_FACET[matching_rows[0][:rez_desk]]
        if !rez_building.nil?
          new_building_facet_vals << rez_building
        else
          new_building_facet_vals << home_bldg
        end
      else
        new_building_facet_vals << home_bldg
      end
    }
    solr_input_doc.removeField("building_facet")
    if new_building_facet_vals.uniq.size > 0 && new_building_facet_vals != [nil]
      @solrj_wrapper.add_vals_to_fld(solr_input_doc, "building_facet", new_building_facet_vals.uniq)
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
  
  protected  #-------------------------- protected -------------------------------
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def get_matching_item_from_values(desired_barcode, item_display_values)
    item_display_values.find { |idv|
      desired_barcode.strip == item_disp_val_hash(idv)[:barcode]
    }
  end

  
  # converts the passed item_display field value into a hash containing the desired pieces
  # @param item_display_val the value of an item_display field in a Solr document
  def item_disp_val_hash(item_display_val)
    if item_display_val.nil?
      {}
    else
      idv_array = item_display_val.split("-|-").map{|w| w.strip }
      { 
        :barcode => idv_array[0],
        :building => idv_array[1]
        # :home_location => idv_array[2],
        # :current_location => idv_array[3],
        # :callnum_type => idv_array[4],
        # :trunc_callnum => idv_array[5],
        # :trunc_shelfkey => idv_array[6],
        # :reverse_shelfkey => idv_array[7],
        # :full_callnum => idv_array[8],
        # :full_shelfkey => idv_array[9]
      }
    end
  end

end