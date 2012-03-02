include Java

# Methods required to interact with SolrJ objects
class SolrjWrapper
  
  attr_reader :streaming_update_server
  
  def initialize(solrj_jar_dir)
    load_solrj(solrj_jar_dir)
    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
    @streaming_update_server = streaming_update_server
  end
  
  # returns a SolrJ StreamingUpdateSolrServer object 
  def streaming_update_server
    @streaming_update_server ||= org.apache.solr.client.solrj.impl.StreamingUpdateSolrServer.new(solr_url, 100, 2)
  end
  
  # given a SolrInputDocument, add the field and/or the values.  This will not add empty values, and it will not add duplicate values
  def add_vals_to_fld(solr_input_doc, fldname, val_array)
    if !fldname.nil? && fldname.size > 0 && !val_array.nil? && val_array.size > 0
      if !solr_input_doc[fldname].nil?
        existing_vals = solr_input_doc[fldname].getValues
      end
      val_array.each { |val|  
        if existing_vals.nil? || !existing_vals.contains(val)
          solr_input_doc.addField(fldname, val, 1.0)
        end
      }
    end
  end
  
  protected 

  # require all the necessary jars to use Solrj classes
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