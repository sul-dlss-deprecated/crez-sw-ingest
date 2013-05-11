require 'parse_crez_data'
require 'solrj_wrapper'
require 'add_crez_to_solr_doc'
require 'logger'

# Use this class to take a csv file containing course reserve data and add the appropriate information to the 
# appropriate Solr Documents.
class CrezIndexer
  
  # @param solrmarc_wrapper  SolrmarcWrapper object for accessing SolrMarc 
  # @param solrj_wrapper  SolrjWrapper for using SolrJ objects
  def initialize(solrmarc_wrapper, solrj_wrapper, log_level=Logger::INFO, log_file=STDERR)
    @logger = Logger.new(log_file)
    @logger.level = log_level
    @solrmarc_wrapper = solrmarc_wrapper
    @solrj_wrapper = solrj_wrapper
    @sus = solrj_wrapper.streaming_update_server
  end
  
  # Given the full path to a file containing course reserve data, 
  #   1)  remove stale course reserve information, including Solr docs that no longer have any course reserve info
  #   2)  add the course reserve data from the file to the correct Solr documents and update the index
  # @param crez_data_file  full path to the course reserve data file, a csv file created from Sirsi Symphony by a script written by Darsi
  def index_crez_data(crez_data_file)
    @logger.unknown("Starting Course Reserve Processing")
    ckey_2_crez_info = get_ckey_2_crez_info(crez_data_file)

    @logger.unknown("Starting Course Reserve Indexing")

    @logger.unknown("Removing Stale Course Reserve Data")
    prev_ckeys = get_crez_ckeys_from_index
    remove_stale_crez_data(prev_ckeys, ckey_2_crez_info.keys)

    @logger.unknown("Adding Course Reserve Data")
    add_crez_data(ckey_2_crez_info)

    @logger.unknown("Starting Course Reserve Commit")
    send_ix_commit
    @logger.unknown("Ending Course Reserve Data Processing")
  end
  
  # Get an array containing ids of solr docs that have course reserve information
  #  uses the access_facet "Course Reserve" value to identify the Solr documents.
  #  Intended to default to getting ALL the docs with course reserve data
  # @param num_to_return - the number of ids to get.  defaults to 4500, 
  #  which is more than all the docs with crez info for a given term (roughly 3800, in general)
  # @return an array containing ids of Solr documents that have crez info
  def get_crez_ckeys_from_index(num_to_return=4500)
    q = org.apache.solr.client.solrj.SolrQuery.new
    q.setQuery("crez_course_id_search:[* TO *]")
    q.setParam("qt", @solrmarc_wrapper.req_handler)
    q.setParam("fl", "id")
    q.setRows(num_to_return)
    q.setFacet(false)
    doc_list = @solrj_wrapper.get_query_result_docs(q)
    current_crez_ckeys = []
    doc_list.each { |doc| 
      current_crez_ckeys << doc["id"]
    }
    current_crez_ckeys
  end
  
  # Remove crez data from those Solr documents that no longer have any crez data.  When a Solr doc
  #  with crez data in the index no longer has its ckey in the crez data file from Symphony, that Solr doc
  #  is reindexed from the marcxml only and and is rewritten to the index.
  # @param ckeys_from_index an Array containing ids of Solr documents that have crez info in the index
  # @param ckeys_from_data an Array containing ids of Solr documents that will be written with current crez info
  #   Note that the current crez data file will cause all implicated solr documents to be rewritten
  def remove_stale_crez_data(ckeys_from_index, ckeys_from_data)
    ckeys_from_index.each { |ix_ckey|
      if !ckeys_from_data.include?(ix_ckey)
        sid = @solrmarc_wrapper.get_solr_input_doc_from_marcxml(ix_ckey)
        add_solr_doc_to_ix(sid, ix_ckey)
      end
    }
  end
  
  # Given ckeys mapped to crez data, create new SolrInputDocument objects for
  #  each ckey that contain the fields from the marcxml and from the crez data,
  #  and add each document to the Solr index 
  # @param ckey_2_crez_info  Hash of ckeys mapped to Array of CSV::Row objects containing course reserve data for the ckey.
  def add_crez_data(ckey_2_crez_info)
    ac2sd = AddCrezToSolrDoc.new(ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper, @logger.level)
    ckey_2_crez_info.keys.each { |ckey|
      sid = ac2sd.add_crez_info_to_solr_doc(ckey)
      add_solr_doc_to_ix(sid, ckey)
    }
  end
  
  
protected  
  
  # Given the full path to a file containing course reserve data, create a Hash ckey => crez_info data
  # @param crez_data_file  full path to the course reserve data file, a csv file created from Sirsi Symphony by a script written by Darsi
  # @return Hash with key of ckey, value an Array of CSV::Row objects each containing data pertaining to a specific item (barcode) associated with the ckey
  def get_ckey_2_crez_info(crez_data_file)
    p = ParseCrezData.new(@logger.level)
    p.read(crez_data_file)
    p.ckey_2_crez_info
  end
    
    
  # retrieves the full marc record stored in the Solr index, runs it through SolrMarc indexing to get a SolrInputDocument that contains no course reserve information
  #  note that it identifies Solr documents by the "id" field, and expects the marc to be stored in a Solr field "marcxml"
  #  if there is no single document matching the id, an error is logged and nil is returned
  # @param id  the value of the "id" Solr field for the record to be retrieved
  def get_solr_input_doc_wo_crez(id)
     @solrmarc_wrapper.get_solr_input_doc_from_marcxml(id)
  end
  
  # add the doc to Solr by calling add on the Solrj StreamingUpdateServer object
  # @param solr_input_doc - the SolrInputDocument to be added to the Solr index
  # @param id - the id of the Solr document, used for log messages
  def add_solr_doc_to_ix(solr_input_doc, id)
    unless solr_input_doc.nil?
      begin
        @sus.add(solr_input_doc)
        @logger.info("updating Solr document #{id}")        
      rescue org.apache.solr.common.SolrException => e 
        @logger.error("SolrException while indexing document #{id}")
        @logger.error("#{e.message}")
        @logger.error("#{e.backtrace}")
      end
    end
  end
  
  # send a commit to the Solrj StreamingUpdateServer object
  def send_ix_commit
    begin
      update_response = @sus.commit
    rescue org.apache.solr.common.SolrException => e
      @logger.error("SolrException while committing updates")
      @logger.error("#{e.message}")
      @logger.error("#{e.backtrace}")
    end
  end
  
end
