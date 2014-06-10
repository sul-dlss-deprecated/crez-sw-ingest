require File.expand_path('../spec_helper', __FILE__)
require 'crez_indexer'
require 'rsolr'

describe CrezIndexer do
  before(:all) do
    #solrmarc points to a solr with the marc docs needed for testing, @solr points to a local solr to receive the documents
    @solrmarc_wrapper = SolrmarcWrapper.new(@@settings.solrmarc_dist_dir, @@settings.solrmarc_conf_props_file, @@settings.solr_source_url)
    @solrj_wrapper = SolrjWrapper.new(@@settings.solrj_jar_dir, @@settings.solr_url)
    @solr ||=  RSolr.connect :url => @@settings.solr_url, :read_timeout => 3600, :open_timeout => 3600
    @crez_indexer = CrezIndexer.new(@solrmarc_wrapper, @solrj_wrapper)
  end
  
  context "get_crez_ckeys_from_index" do
    before(:all) do
      @crez_ckeys = @crez_indexer.get_crez_ckeys_from_index(5)
    end

    it "should return a list of Symphony ckeys" do
      @crez_ckeys.should_not be_nil
      @crez_ckeys[0].to_i.should be_an_instance_of(Fixnum)
    end
    
    it "should only return docs with crez data" do
      # will need to do a write to ensure this is true
      @crez_ckeys.each { |ckey|  
        ensure_solr_doc_has_crez_info(ckey)
      }
    end

#    it "should return ALL the docs with crez data, up to num_to_return limit" do
#      pending "to be implemented once a standalone test index is used"
#    end
  end
  
  context "remove_stale_crez_data" do
    it "should remove crez data when the ckey no longer has crez data" do
      i = crez_indexer_stub
      i.should_receive(:add_solr_doc_to_ix).twice
      i.should_not_receive(:add_solr_doc_to_ix).with(hash_including("crez_course_info"))
      ix_ckeys = ["1", "2"]
      data_ckeys = ["3", "4"]
      i.remove_stale_crez_data(ix_ckeys, data_ckeys)
    end
    
    it "should leave solr doc alone if ckey is in current crez data" do
      i = crez_indexer_stub
      i.should_receive(:add_solr_doc_to_ix).with do |sid_arg|
        sid_arg["id"].getValue.should == "1"
      end.once
      ix_ckeys = ["1", "2"]
      data_ckeys = ["2", "4"]
      i.remove_stale_crez_data(ix_ckeys, data_ckeys)
    end
  end

  context "add_crez_data" do
    before(:all) do
      p = ParseCrezData.new
      p.read(File.expand_path('test_data/multfirst.csv', File.dirname(__FILE__)))
      @ckey_2_crez_info = p.ckey_2_crez_info
    end

    it "should call add_crez_info_to_solr_doc for each ckey in the crez data" do
      AddCrezToSolrDoc.any_instance.should_receive(:add_crez_info_to_solr_doc).with(any_args).exactly(@ckey_2_crez_info.keys.size).times
      i = crez_indexer_stub
      i.add_crez_data(@ckey_2_crez_info)
    end

    it "should call add_solr_doc_to_ix for each ckey in the crez data" do
      i = crez_indexer_stub
      i.should_receive(:add_solr_doc_to_ix).exactly(@ckey_2_crez_info.keys.size).times
      i.add_crez_data(@ckey_2_crez_info)
    end
  end

  context "index_crez_data" do
    before(:all) do
      @rezdeskbldg_data_file = File.expand_path('test_data/rezdeskbldg.csv', File.dirname(__FILE__))
    end
    
    it "should call remove_stale_crez_data once" do
      i = crez_indexer_stub
      i.should_receive(:remove_stale_crez_data).once
      i.index_crez_data(@rezdeskbldg_data_file)
    end
    
    it "should call add_crez_data once" do
      i = crez_indexer_stub
      i.should_receive(:add_crez_data).once
      i.index_crez_data(@rezdeskbldg_data_file)
    end
    
    it "should call add_solr_doc_to_ix for each doc being updated" do
      i = crez_indexer_stub
      i.should_receive(:add_solr_doc_to_ix).exactly(10).times
      i.index_crez_data(@rezdeskbldg_data_file)
    end
    
    it "should call send_ix_commit end of processing" do
      i = crez_indexer_stub
      i.stub(:add_solr_doc_to_ix).with(any_args)
      i.should_receive(:send_ix_commit).once
      i.index_crez_data(@rezdeskbldg_data_file)
    end
    
    it "should update the Solr Doc with crez info and write to index (integration test)" do
      # ensure plain doc
      sid_8707706_b4 = get_solr_doc("8707706")
      if sid_8707706_b4 == nil || !sid_8707706_b4["crez_course_info"].nil?
        # need to create a stub doc from the marc so it has no crez fields, and send it to the destination solr.
        p = ParseCrezData.new
        p.read(@rezdeskbldg_data_file)
        a = AddCrezToSolrDoc.new(p.ckey_2_crez_info, @solrmarc_wrapper, @solrj_wrapper)
        sid_8707706_marcxml_only = a.solr_input_doc("8707706")
        if sid_8707706_marcxml_only != nil
          @solrj_wrapper.add_doc_to_ix(sid_8707706_marcxml_only, "8707706")
          @solrj_wrapper.commit
          sid_8707706_b4 = sid_8707706_marcxml_only
        end
      end
      sid_8707706_b4.should_not == nil
      sid_8707706_b4["crez_course_info"].should == nil
      sid_8707706_b4["item_display"].each { |val|  
          val.split("-|-").size.should == 10
      }

      # add crez data to index
      @crez_indexer.stub(:remove_stale_crez_data)
      @crez_indexer.index_crez_data(@rezdeskbldg_data_file)
      sid_8707706_after = get_solr_doc("8707706")
      sid_8707706_after["crez_course_info"].should_not == nil
      sid_8707706_after["last_updated"].should_not == sid_8707706_b4["last_updated"]
      sid_8707706_after["item_display"].each { |val|
        if val.match(/36105215224689|36105215166732/)
          val.split("-|-").size.should == 13
        else
          val.split("-|-").size.should == 10
        end
      }
    end
    
  end # index_crez_data context
end


# get the solr document object
def get_solr_doc(doc_id)
  solr_params = {:qt => "document", :id => doc_id}
  response = @solr.get 'select', :params => solr_params, :wt => "ruby"
  num_found = response["response"]["numFound"]
  if num_found == 0
    return nil
  elsif num_found > 1
    raise "Solr retrieved more than one document for id #{doc_id}"
  end
  solr_doc = response["response"]["docs"].first
  raise "Solr retrieved document with 'id' #{solr_doc["id"]} but expected #{doc_id}" unless doc_id == solr_doc["id"]
  solr_doc
end

# get the Solr document from the index using @solrj_wrapper and ensure there is course reserve information in the document
def ensure_solr_doc_has_crez_info(doc_id)
  q = org.apache.solr.client.solrj.SolrQuery.new
  q.setParam("qt","document")
  q.setParam("id", doc_id)
  q.setParam("fl", "crez_course_info")
  q.setFacet(false)
  doc_list = @solrj_wrapper.get_query_result_docs(q)
  doc_list[0]["crez_course_info"].should_not be_nil
end  

# return an CrezIndexer object with the Solr update methods stubbed
def crez_indexer_stub
  i = CrezIndexer.new(@solrmarc_wrapper, @solrj_wrapper)
  i.stub(:get_crez_ckeys_from_index).with(any_args).and_return(["1", "2"])
  i.stub(:add_solr_doc_to_ix).with(any_args)
  i.stub(:send_ix_commit)
  return i
end
