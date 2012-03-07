include Java

# Methods required to interact with SolrJ objects
class SolrjWrapper
  
  attr_reader :streaming_update_server
  
  def initialize(solrj_jar_dir)
    if not defined? JRUBY_VERSION
      raise "SolrjWrapper only runs under jruby"
    end
    load_solrj(solrj_jar_dir)
    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
    @streaming_update_server = streaming_update_server
    useJavabin!
  end
  
  # Send requests using the Javabin binary format instead of serializing to XML
  # Requires /update/javabin to be defined in solrconfig.xml as
  # <requestHandler name="/update/javabin" class="solr.BinaryUpdateRequestHandler" />
  def useJavabin!
    @streaming_update_server.setRequestWriter Java::org.apache.solr.client.solrj.impl.BinaryRequestWriter.new
  end
  
  
  # returns a SolrJ StreamingUpdateSolrServer object 
  def streaming_update_server
    @streaming_update_server ||= org.apache.solr.client.solrj.impl.StreamingUpdateSolrServer.new(solr_url, 100, 2)
  end
  
  # given a SolrInputDocument, add the field and/or the values.  This will not add empty values, and it will not add duplicate values
  # @param solr_input_doc - the SolrInputDocument object receiving a new field value
  # @param fld_name - the name of the Solr field
  # @param val_array - an array of values for the Solr field
  def add_vals_to_fld(solr_input_doc, fld_name, val_array)
    unless val_array.nil?
      val_array.each { |value|  
        add_val_to_fld(solr_input_doc, fld_name, value)
      }
    end
  end

  # given a SolrInputDocument, add the field and/or the value.  This will not add empty values, and it will not add duplicate values
  # @param solr_input_doc - the SolrInputDocument object receiving a new field value
  # @param fld_name - the name of the Solr field
  # @param value - the value to add to the Solr field
  def add_val_to_fld(solr_input_doc, fld_name, value)
    if !fld_name.nil? && fld_name.size > 0 && !value.nil? && value.size > 0
      if !solr_input_doc[fld_name].nil? && solr_input_doc
        existing_vals = solr_input_doc[fld_name].getValues
      end
      if existing_vals.nil? || !existing_vals.contains(value)
        solr_input_doc.addField(fld_name, value, 1.0)
      end
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