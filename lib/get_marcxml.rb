require 'rsolr'
require 'yaml'

# Given a Solr baseurl from config/solr.yml and a Solr document id, send a request to Solr to retrieve marcxml for that record.
class GetMarcxml
  
  # FIMXE:  method definitions or instance variables?
  
  def initialize
    # parameters to retrieve marcxml with a solr request
    # solr_params should be in solr.yml config file
    @solr_params = {:qt => "document", :fl => "id,marcxml", :echoParams => "none"}

    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
  end
  
  # set solr_url to value of "url" in config/solr.yml`
  def solr_url
    @solr_url ||= begin
      raise "You are missing the config/solr.yml file: #{@solr_config_file}. " unless File.exists?(@solr_config_file) 
      @solr_config = YAML::load(File.open(@solr_config_file))
      raise "config/solr.yml must have a value for 'url'" unless @solr_config["url"] 
      @solr_config["url"]
    end
  end
  
  # set up the solr connection
  def solr
    # if running on same box as Solr, consider using a direct connection (not http) w rsolr-direct?
    @solr ||=  RSolr.connect :url => solr_url
  end
 
  # send solr a query and return the response
  def get_solr_document(doc_id)
    @solr_params[:id] = doc_id
    @response = solr.get 'select', :params => @solr_params, :wt => "ruby"
    raise "Solr retrieved more than one document for id #{doc_id}" unless @response["response"]["numFound"] == 1
    @solr_doc = @response["response"]["docs"].first
    raise "Solr retrieved document with 'id' #{@solr_doc["id"]} but expected #{doc_id}" unless doc_id == @solr_doc["id"]
    @solr_doc
  end
  
  # @return the marcxml as a string
  def get_marcxml(doc_id)
    @solr_doc ||= get_solr_document(doc_id)
    @solr_doc["marcxml"]
  end
  
end