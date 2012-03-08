require 'yaml'

# Read the .yml file containing the configuration values
class Settings
  
  attr_reader :solrmarc_dist_dir, :solrmarc_conf_props_file, :solr_url, :solrj_jar_dir, :solrj_queue_size, :solrj_num_threads
  
  def initialize(env)
    config = YAML.load_file('config/crez_sw_ingest.yml')[env]
    @solrmarc_dist_dir = config["solrmarc_dist_dir"]
    @solrmarc_conf_props_file = config["solrmarc_conf_props_file"]
    @solr_url = config["solr_url"]
    @solrj_jar_dir = config["solrj_jar_dir"]
    @solrj_queue_size = config["solrj_queue_size"]
    @solrj_num_threads = config["solrj_num_threads"]
  end
  
end