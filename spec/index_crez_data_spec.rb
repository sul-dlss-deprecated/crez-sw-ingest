require File.expand_path('../spec_helper', __FILE__)
require 'index_crez_data'
require 'parse_crez_data'
require 'rsolr'

describe IndexCrezData do
  before(:all) do
    @@solrmarc_wrapper = SolrmarcWrapper.new(@@settings.solrmarc_dist_dir, @@settings.solrmarc_conf_props_file, @@settings.solr_url)
    @@solrj_wrapper = SolrjWrapper.new(@@settings.solrj_jar_dir, @@settings.solr_url, @@settings.solrj_queue_size, @@settings.solrj_num_threads)
    @@sus = @@solrj_wrapper.streaming_update_server
    @@solr ||=  RSolr.connect :url => @@settings.solr_url
    @@index_crez_data = IndexCrezData.new
    p = ParseCrezData.new
    crez_data_file = File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__))
    p.read(crez_data_file)
    @@a = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @@solrmarc_wrapper, @@solrj_wrapper)
    sid_8707706_marcxml_only = @@a.solr_input_doc("8707706")
    @@sus.add(sid_8707706_marcxml_only)
    @@sus.commit
    @@sid_8707706_b4 = get_solr_doc("8707706")
    @@index_crez_data.index_crez_data(crez_data_file, @@solrmarc_wrapper, @@solrj_wrapper)
    @@sid_8707706_after = get_solr_doc("8707706")
  end
  
  it "should replace the existing Solr Doc in the index with the revised document with crez info" do
    @@sid_8707706_b4["crez_instructor_search"].should be_nil
    @@sid_8707706_b4["crez_instructor_facet"].should be_nil
    @@sid_8707706_b4["crez_display"].should be_nil
# item_display field must be one with barcode match    
#    item_display_val_b4 = @@sid_8707706_b4["item_display"].first
#    item_display_val_b4.split("-|-").size.should == 10
    @@sid_8707706_after["crez_course_info"].should_not be_nil
    @@sid_8707706_after["last_updated"].should_not == @@sid_8707706_b4["last_updated"]
#    item_display_val_after = sid_8707706_after["item_display"]   
#    item_display_val_after.split("-|-").size.should == 13
  end

end

# get the solr document object
def get_solr_doc(doc_id)
  solr_params = {:qt => "document", :id => doc_id}
  response = @@solr.get 'select', :params => solr_params, :wt => "ruby"
  raise "Solr retrieved more than one document for id #{doc_id}" unless response["response"]["numFound"] == 1
  solr_doc = response["response"]["docs"].first
  raise "Solr retrieved document with 'id' #{solr_doc["id"]} but expected #{doc_id}" unless doc_id == solr_doc["id"]
  solr_doc
end

