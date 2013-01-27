require 'spec_helper'

describe "CMIS" do
  shared_examples_for "a CMIS repository" do |atom_url, user, password|
    before(:all) do
      @atom_url = atom_url
      @user = user
      @password = password
      @repos = CMIS::repositories(@atom_url, @user, @password)
      @session = CMIS::create_session(@atom_url, @user, @password, @repos[0].id)
      @test_folder_name = "JRUBY_CMIS_TEST_" + random_name
      @test_folder = @session.root_folder.create_cmis_folder(@test_folder_name)
    end

    after(:all) do
      @test_folder.delete_tree(true, CMIS::UnfileObject::DELETE, true)
    end

    describe "Repository functionality" do
      it "should create a session" do
        @session.is_a?(Java::OrgApacheChemistryOpencmisClientRuntime::SessionImpl).should be_true
      end
    
      it "should create a session against the first repository" do
        @simple_session = CMIS::create_session(@atom_url, @user, @password)
        @simple_session.is_a?(Java::OrgApacheChemistryOpencmisClientRuntime::SessionImpl).should be_true 
      end

      it "should retrieve all available repositories" do
        @repos.is_a?(Java::JavaUtil::ArrayList).should be_true
      end

      it "should have one repository with a name" do
        repo = @repos[0]
        repo.name.should_not be_empty
      end

      it "should be possible to read the repository info" do
        rep_info = @session.repository_info
        cap = rep_info.capabilities

        # Just testing a few of them
        cap.is_get_descendants_supported.should == true
        cap.is_get_folder_tree_supported.should == true
        cap.changes_capability.value.should_not be_empty
        cap.query_capability.value.should_not be_empty
        cap.join_capability.value.should_not == be_empty
      end
    end

    describe "Reading objects" do
      it "should be possible to find the contents of the root folder" do
        root = @session.root_folder
        children = root.children
        children.map(&:name).should include(@test_folder_name)
      end

      it "should display the properties of an object" do
        props = @session.root_folder.properties   
        props.each do |p|
          disp_name = p.definition.display_name
          p.value_as_string.should == "/" if disp_name == "Path"
          p.value_as_string.should == "cmis:folder" if disp_name == "Type-Id"
          p.value_as_string.should_not be_nil if disp_name == "Name"
          p.value_as_string.should be_nil if disp_name == "Parent Id"
        end
      end

      it "should be possible to get a property explicitly" do
        # A couple of folder specific props that we can access explicitly
        root = @session.root_folder
        root.is_root_folder.should == true
        root.path.should == "/"
      end

      it "should retrieve allowable actions for an object" do
        allowed_actions = @session.root_folder.allowable_actions.allowable_actions # Are you kidding me!!?
        allowed_actions.to_a.should include(CMIS::Action::CAN_GET_PROPERTIES)
      end

      it "should be possible to check if a document is versionable" do
        file = file_path("text_file.txt")
        name = random_name + ".txt"
        id = @test_folder.create_cmis_document(name, file)
        doc = @session.get_object(id)
        doc.type.is_versionable.should == true
      end

      it "should be possible to access information about renditions" do
        file = file_path("document.pdf")
        file_name = random_name + ".pdf"
        id = @test_folder.create_cmis_document(file_name, file)      
        context = @session.create_operation_context
        context.rendition_filter_string = "cmis:thumbnail"
        @session.clear
        doc = @session.get_object(id, context)

        renditions = doc.renditions
        # TODO: Fix this test.
        #renditions.size.should >= 1
        renditions.each do |r|
          r.kind.should_not be_empty
          r.mime_type.should_not be_empty
        end
      end
    end
  end

  describe "Alfresco" do
    atom_url = "http://cmis.alfresco.com/cmisatom"
    user = "admin"
    password = "admin"
    
    it_behaves_like "a CMIS repository", atom_url, user, password
  end

  describe "Nuxeo" do
    atom_url = "http://cmis.demo.nuxeo.org/nuxeo/atom/cmis"
    user = "Administrator"
    password = "Administrator"
    
    it_behaves_like "a CMIS repository", atom_url, user, password
  end
end