require 'parse_crez_data'
require 'solrj_wrapper'
require 'add_crez_to_solr_doc'
require 'logger'

# Use this class to take a csv file containing course reserve data and add the appropriate information to the 
# appropriate Solr Documents.
class IndexCrezData
  
  # Given the full path to a file containing course reserve data, and all the parameter values for indexing,
  #   add the course reserve data to the  create a Hash ckey => crez_info data
  # @param crez_data_file  full path to the course reserve data file, a csv file created from Sirsi Symphony by a script written by Darsi
  # @param solrmarc_wrapper  SolrmarcWrapper object for accessing SolrMarc 
  # @param solrj_wrapper  SolrjWrapper for using SolrJ objects
  def index_crez_data(crez_data_file, solrmarc_wrapper, solrj_wrapper)
# FIXME:  need to log to a file, passed in
    @logger = Logger.new(STDERR)
    @logger.info("Starting Course Reserve Processing")
    ckey_2_crez_info = get_ckey_2_crez_info(crez_data_file)
    @logger.info("Starting Course Reserve Indexing")
    sus = solrj_wrapper.streaming_update_server
    ac2sd = AddCrezToSolrDoc.new(ckey_2_crez_info, solrmarc_wrapper, solrj_wrapper)
    ckey_2_crez_info.keys.each { |ckey|  
      solr_input_doc = ac2sd.add_crez_info_to_solr_doc(ckey)
      unless solr_input_doc.nil?
        begin
          sus.add(solr_input_doc)
          @logger.info("updating Solr document #{ckey}")        
        rescue org.apache.solr.common.SolrException => e 
          @logger.error("SolrException while indexing document #{ckey}")
          @logger.error("#{e.message}")
          @logger.error("#{e.backtrace}")
        end
      end
    }
    @logger.info("Starting Course Reserve Commit")
    # commit
    begin
      update_response = sus.commit
    rescue org.apache.solr.common.SolrException => e
      @logger.error("SolrException while committing updates")
      @logger.error("#{e.message}")
      @logger.error("#{e.backtrace}")
    end
    @logger.info("Ending Course Reserve Data Processing")
  end
  
protected  
  
  # Given the full path to a file containing course reserve data, create a Hash ckey => crez_info data
  # @param crez_data_file  full path to the course reserve data file, a csv file created from Sirsi Symphony by a script written by Darsi
  # @return Hash with key of ckey, value an Array of CSV::Row objects each containing data pertaining to a specific item (barcode) associated with the ckey
  def get_ckey_2_crez_info(crez_data_file)
    p = ParseCrezData.new
    p.read(crez_data_file)
    p.ckey_2_crez_info
  end
    
end