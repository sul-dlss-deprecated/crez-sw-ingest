include Java

# Given marcxml, call SolrMarc to prepare a Solr Document from the marcxml, and get the Solr Document created.
# The Solr Document is NOT written to Solr.
class MarcToSolrDoc
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def initialize(solr_marc_dir, config_props_fname)
    load_solr_marc(solr_marc_dir)
    # the full path for the config/solr.yml file
    @solr_config_file = File.expand_path('../config/solr.yml', File.dirname(__FILE__))
    set_up_solr_reindexer(solr_url, config_props_fname)
    
  end
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def get_solr_input_doc(doc_id)
    @solrmarc_reindexer.getSolrInputDoc("id", "666", "marcxml")
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
  
  
  protected
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def load_solr_marc(solr_marc_dir)
#    $CLASSPATH << solr_marc_dir
    require "#{solr_marc_dir}/StanfordSearchWorksSolrMarc.jar"
    require "#{solr_marc_dir}/SolrMarc.jar"
    Dir["#{solr_marc_dir}/lib/*.jar"].each {|jar_file| require jar_file }
    
    # not sure about this
#    Dir["#{solr_marc_dir}/*.properties"].each {|file| require file }
  end

=begin  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  def solrmarc_reindexer(solr_url, config_props_fname)
    @solrmarc_reindexer ||= begin
      solr_core_loader = org.solrmarc.solr.SolrCoreLoader.loadRemoteSolrServer(solr_url, false, true)
      @solrmarc_reindexer = org.solrmarc.marc.SolrReIndexer.new(solr_core_loader)
      @solrmarc_reindexer.init([config_props_fname])
      @solrmarc_reindexer
    end
  end
=end  
  

# FIXME:  use the above, not the below
  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  # @solr_url 
  # @config_props_fname  the name of the xx_config.properties file relative to the solr_marc_directory
  def set_up_solr_reindexer(solr_url, config_props_fname)
    solr_core_loader = org.solrmarc.solr.SolrCoreLoader.loadRemoteSolrServer(solr_url, false, true)
    @solrmarc_reindexer = org.solrmarc.marc.SolrReIndexer.new(solr_core_loader)
    @solrmarc_reindexer.init([config_props_fname])
  end
  
  
=begin  
  # NAOMI_MUST_COMMENT_THIS_METHOD
  # @config_props_fname  relative to the solr_marc_directory
  def get_solrj_solr_server(solr_url, config_props_fname)
    solr_core_loader = org.solrmarc.solr.SolrCoreLoader.loadRemoteSolrServer(solr_url, false, true)
    @solrmarc_reindexer = org.solrmarc.marc.SolrReIndexer.new(solr_core_loader)
    @solrmarc_reindexer.init([config_props_fname])
  end
=end
  
  
# FIXME:  need to create a SolrMarc class/method that:
#  1.  creates a Marc Record object from marcxml
#  2.  calls SolrIndexer  (well, the localized version) for the record object to get fldNames2vals map
#  3.  calls SolrObjectUtils.createSolrInputDoc
  
  
  
=begin

  		prepareToWriteToIndex(useBinaryRequestHandler, useStreamingProxy, testSolrUrl);
            solrProxy = SolrCoreLoader.loadRemoteSolrServer(testSolrUrl + "/update", useBinaryRequestHandler, useStreamingProxy);
        		logger.debug("just set solrProxy to remote server at "	+ testSolrUrl + " - " + solrProxy.toString());
        		solrJSolrServer = ((SolrServerProxy) solrProxy).getSolrServer();



  //		solrProxy.deleteAllDocs();
  //		solrProxy.commit(false); // don't optimize
  		solrJSolrServer.deleteByQuery("*:*");
  		logger.debug("just deleted all docs known to the solrProxy");

  		runMarcImporter(configPropFilename, testDataParentPath, marcTestDataFname);
            if (marcTestDataFname != null)
        		{
        			importer = new MarcImporter(solrProxy);
        			importer.init(new String[] { configPropFilename, testDataParentPath + File.separator + marcTestDataFname });
        			importer.importRecords();
        		}



  protected String siteDir = "stanford-sw";

  // set up required properties when tests not invoked via Ant
  // hardcodings below are only used when the tests are invoked without the
  //  properties set (e.g. from eclipse)
  {
        String configPropFile = System.getProperty("test.config.file");
  	if (configPropFile == null)
            System.setProperty("test.config.file", siteDir + File.separator + "sw_config.properties");

        // used to find site translation_maps
  	if (System.getProperty("solrmarc.site.path") == null)
            System.setProperty("solrmarc.site.path", siteDir);

  	// used to find test data files
  	testDataParentPath = System.getProperty("test.data.path");
        if (testDataParentPath == null)
        {
            testDataParentPath = System.getProperty("test.data.parent.path");
            if (testDataParentPath == null)
                testDataParentPath = siteDir + File.separator + "test" + File.separator + "data";
            System.setProperty("test.data.path", testDataParentPath);
        }
  }
=end  
  
  
  
  
end