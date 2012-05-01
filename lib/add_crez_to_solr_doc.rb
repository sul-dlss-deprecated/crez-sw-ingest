# put config directory on load path to find translation files
conf_dir = File.expand_path('../config/', File.dirname(__FILE__))
$:.push conf_dir unless $:.include?(conf_dir)

require 'solrmarc_wrapper'
require 'solrj_wrapper'
require 'logger'
require 'dept_translations'
require 'rez_desk_translations'
require 'library_code_translations'
require 'loan_period_translations'

# key method:  add_crez_info_to_solr_doc(ckey)
#   class is initialized with Hash of ckeys mapped to Array of CSV::Row objects containing course reserve data for the ckey.
#   so given a ckey, add_crez_info_to_solr_doc(ckey) will recreate the SearchWorks solr doc from the marcxml and will add the
#   course reserve data to it.
class AddCrezToSolrDoc
  include RezDeskTranslations
  include LibraryCodeTranslations
  include LoanPeriodTranslations
  include DeptTranslations
  
  attr_reader :ckey_2_crez_info
  attr_accessor :logger

  # @param ckey_2_crez_info  Hash of ckeys mapped to Array of CSV::Row objects containing course reserve data for the ckey.
  # @param solrmarc_wrapper  SolrmarcWrapper object for accessing SolrMarc 
  # @param solrj_wrapper  SolrjWrapper for using SolrJ objects
  def initialize(ckey_2_crez_info, solrmarc_wrapper, solrj_wrapper, log_level=Logger::INFO, log_file=STDERR)
    if not defined? JRUBY_VERSION
      raise "AddCrezToSolrDoc only runs under jruby"
    end
    @solrmarc_wrapper = solrmarc_wrapper
    @solrj_wrapper = solrj_wrapper
    @ckey_2_crez_info = ckey_2_crez_info
    @logger = Logger.new(log_file)
    @logger.level = log_level
  end

# FIXME:  do we have the crez_rows already?  b/c aren't we going to step through the crez data file by ckey?  
# Or through a list of ids to delete crez data, then list of ids to add crez data, derived from a parse through csv file and comparison to database table?
  # given a ckey, 
  #  1. calls solrmarc_wrapper to retrieve a SolrInputDoc derived from the marcxml in the Solr index
  #  2. gets the relevant course reserve data from the reserves-dump .csv file
  #  3. adds the course reserve info to the SolrInputDoc
  # @param ckey the id of the existing Document in the Solr index
  def add_crez_info_to_solr_doc(ckey)
    solr_input_doc = solr_input_doc(ckey)
    unless solr_input_doc.nil?  # if solr_input_doc was nil, then error has already been logged by solrmarc_wrapper
      crez_rows = crez_info(ckey)
      if crez_rows.nil?
        @logger.error "Ckey #{ckey} has no rows in the Course Reserves csv data"
        return
      else
        crez_rows.each { |crez_row|
          # add new fields
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_instructor_search", crez_row[:instructor_name])
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_course_name_search", crez_row[:course_name])
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_course_id_search", crez_row[:course_id])
          # note that instructor and course are copy fields
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_desk_facet", REZ_DESK_2_REZ_LOC_FACET[crez_row[:rez_desk]])
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_dept_facet", get_dept(crez_row[:course_id]))
          @solrj_wrapper.add_val_to_fld(solr_input_doc, "crez_course_info", get_compound_value_from_row(crez_row, [:course_id, :course_name, :instructor_name], " -|- "))
          # update item_display value with crez data
          item_display_vals = solr_input_doc["item_display"].getValues
          orig_item_disp_val = get_matching_item_from_values(crez_row[:barcode], item_display_vals)
          if orig_item_disp_val.nil?
            @logger.error "Solr Document for #{ckey} has no item with barcode #{crez_row[:barcode].strip}"
          else
            item_display_vals_array = java.util.ArrayList.new(item_display_vals)
            ix = item_display_vals_array.indexOf(orig_item_disp_val)
            new_item_disp_val = update_item_display(orig_item_disp_val, crez_row)
            item_display_vals_array.set(ix, new_item_disp_val)
            @solrj_wrapper.replace_field_values(solr_input_doc, "item_display", item_display_vals_array)
          end
        }
        update_building_facet(solr_input_doc, crez_rows) # could work this logic in here if performance is an issue
      end
    end
    solr_input_doc
  end

  # retrieves the full marc record stored in the Solr index, runs it through SolrMarc indexing to get a SolrInputDocument that contains no course reserve information
  #  note that it identifies Solr documents by the "id" field, and expects the marc to be stored in a Solr field "marcxml"
  #  if there is no single document matching the id, an error is logged and nil is returned
  # @param id  the value of the "id" Solr field for the record to be retrieved
  def solr_input_doc(id)
     @solrmarc_wrapper.get_solr_input_doc_from_marcxml(id)
  end

  # populates (and returns) crez_info with the Array of CSV::Row objects from the reserves data that pertain to the ckey
  def crez_info(ckey)
    @ckey_2_crez_info[ckey]
  end
  
  # No longer used -- 2011-04-04
  # add a value "Course Reserve" to the access_facet field of the solr_input_doc
  # @param solr_input_doc - the SolrInputDocument to be changed
  def add_crez_val_to_access_facet(solr_input_doc)
    @solrj_wrapper.add_val_to_fld(solr_input_doc, "access_facet", "Course Reserve")
  end

# FIXME:  maybe move this into add_crez_info_to_solr_doc method?
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
  
  # Note: there is no checking here to ensure the crez_row barcode matches the item_display barcode
  # @param orig_item_display_val - the original value of the item_display field
  # @param crez_row - the CSV::Row object containing the information to be appended to the item_display value
  # @return an item_display value string with course reserve values appended, and current location set to the rez_desk if curr_loc is checked out
  def update_item_display(orig_item_display_val, crez_row)
    sep = " -|- "
    rez_desk = crez_row[:rez_desk]
    rez_desk ||= ""
    loan_period = LOAN_CODE_2_USER_STR[crez_row[:loan_period]]
    loan_period ||= ""
    course_id = crez_row[:course_id]
    course_id ||= ""
    suffix = course_id + sep + rez_desk + sep + loan_period
    # replace current location in existing item_display field with rez_desk
    old_val_array = orig_item_display_val.split(' -|- ', -1)
    old_val_array[3] = rez_desk
    new_val = old_val_array.join(' -|- ')
    new_val + " -|- " + suffix
  end

# ---------------- FIXME:  probably should be protected ---------------------------

  # derive the department from the course_id
  def get_dept(course_id)
    dept = course_id.split("-")[0]
    dept = dept.split(" ")[0]
    DEPT_CODE_2_USER_STR[dept]
  end
  
  # returns the single item_display field value matching the barcode, or nil if none match
  # @param desired_barcode the barcode of the desired item_display field
  # @param solr_input_doc the SolrInputDocument with item_display fields to be matched
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
    if new_building_facet_vals.uniq.size > 0 && new_building_facet_vals != [nil]
      @solrj_wrapper.replace_field_values(solr_input_doc, "building_facet", new_building_facet_vals.uniq)
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
  
  # returns the single item_display field value matching the barcode, or nil if none match
  # @param desired_barcode the barcode of the desired item_display field
  # @param item_display_values an array of item_display Solr field values of a SolrInputDocument
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
        :building => idv_array[1],
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