require 'get_solrdoc_from_solrmarc'

# NAOMI_MUST_COMMENT_THIS_CLASS
class AddCrezToSolrDoc
  
  attr_reader :ckey_2_crez_info
  
  def initialize(solrmarc_dir, ckey_2_crez_info)
    @get_solr_doc_from_solrmarc = GetSolrdocFromSolrmarc.new(solrmarc_dir, "sw_config.properties")
    @ckey_2_crez_info = ckey_2_crez_info
  end

  # NAOMI_MUST_COMMENT_THIS_METHOD
  def get_solr_input_doc(ckey)
     @solr_input_doc = @get_solr_doc_from_solrmarc.get_solr_input_doc(ckey)
  end

  
end