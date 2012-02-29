require 'marc_to_solr_doc'

describe MarcToSolrDoc do
  
  it "should load everything necessary to call SolrMarc" do
    m = MarcToSolrDoc.new("/Users/ndushay/searchworks/solrmarc-sw/dist", "sw_config.properties")
    m.get_solr_input_doc("666").should_not be_nil
    
    pending "to be implemented - call AccessTests?"
    # java -Xmx1g -Xms1g -cp $CP -jar $SITE_JAR $RAW_DATA_DIR/physicalTests.mrc &>$LOG_DIR/log.txt
  end
  
  it "should retrieve the SolrDoc generated from the marc record" do
    pending "to be implemented"
  end
  
  it "should have a SolrDoc with the non-stored fields present" do
    pending "to be implemented"
  end

  it "should call SolrMarc for each marc record" do
    pending "to be implemented"
  end
  
end


