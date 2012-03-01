include Java

# NAOMI_MUST_COMMENT_THIS_CLASS
class SolrjWrapper
  
  attr_reader :streaming_update_server
  
  def initialize(solrj_jar_dir)
    load_solrj(solrj_jar_dir)
    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
    @streaming_update_server = streaming_update_server
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def streaming_update_server
    @streaming_update_server ||= org.apache.solr.client.solrj.impl.StreamingUpdateSolrServer.new(solr_url, 100, 2)
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def add_value_to_field(solr_input_doc, fldname, value)
    "to be implemented"
  end
  
  
  protected 

#   # require all the necessary jars to use Solrj classes
  def load_solrj(solrj_jar_dir)
    Dir["#{solrj_jar_dir}/*.jar"].each {|jar_file| require jar_file }
  end
  
# FIXME:  duplicated in solrmarc_wrapper ...  
  # set solr_url to value of "url" in config/solr.yml`
  def solr_url
    @solr_url ||= begin
      raise "You are missing the config/solr.yml file: #{@solr_config_file}. " unless File.exists?(@solr_config_file) 
      @solr_config = YAML::load(File.open(@solr_config_file))
      raise "config/solr.yml must have a value for 'url'" unless @solr_config["url"] 
      @solr_config["url"]
    end
  end
  
  
end