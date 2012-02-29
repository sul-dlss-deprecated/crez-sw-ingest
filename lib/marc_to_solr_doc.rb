include Java

# use SolrMarc's SolrReIndexer to get a SolrInputDocument from the marc record stored in the Solr index.
class MarcToSolrDoc
  
  # @solr_marc_dir the "dist" directory from a solrmarc ant build
  # @config_props_fname  the name of the xx_config.properties file relative to the solr_marc_directory
  def initialize(solr_marc_dir, config_props_fname)
    load_solr_marc(solr_marc_dir)
    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
    set_up_solr_reindexer(solr_url, config_props_fname)
    
  end
  
  # retrieves the full marc record stored in the Solr index, runs it through SolrMarc indexing to get a SolrInputDocument
  #  note that it identifies Solr documents by the "id" field, and expects the marc to be stored in a Solr field "marcxml"
  # @doc_id  the value of the "id" Solr field for the record to be retrieved
  def get_solr_input_doc(doc_id)
    @solrmarc_reindexer.getSolrInputDoc("id", doc_id, "marcxml")
  end
  
  
  protected
  
  # require all the necessary jars to use SolrMarc classes
  def load_solr_marc(solr_marc_dir)
    require "#{solr_marc_dir}/StanfordSearchWorksSolrMarc.jar"
    require "#{solr_marc_dir}/SolrMarc.jar"
    Dir["#{solr_marc_dir}/lib/*.jar"].each {|jar_file| require jar_file }
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
  
  # initialize the @solrmarc_reindexer object
  # @solr_url the url of the Solr server
  # @config_props_fname  the name of the xx_config.properties file relative to the solr_marc_dir used in initialize method
  def set_up_solr_reindexer(solr_url, config_props_fname)
    solr_core_loader = org.solrmarc.solr.SolrCoreLoader.loadRemoteSolrServer(solr_url, false, true)
    @solrmarc_reindexer = org.solrmarc.marc.SolrReIndexer.new(solr_core_loader)
    @solrmarc_reindexer.init([config_props_fname])
  end
  
end