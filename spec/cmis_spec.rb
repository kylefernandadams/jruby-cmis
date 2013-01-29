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

      it "should retrieve allowed actions for an object using convenient method" do
        # for a folder
        allowed_actions = @session.root_folder.allowed_actions
        allowed_actions.should include(CMIS::Action::CAN_GET_PROPERTIES)

        doc = create_random_doc(@test_folder)
        allowed_actions = doc.allowed_actions
        allowed_actions.should include(CMIS::Action::CAN_GET_PROPERTIES)
      end

      it "should be possible to check if a document is versionable" do
        doc = create_random_doc(@test_folder)
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

      it "should be possible to download document" do
        doc = create_random_doc(@test_folder)
        file = Dir.tmpdir + doc.name
        doc.download(file)
        File.exists?(file).should == true
        File.delete(file)
      end
    end

    describe "Writing objects" do
      it "should create a folder" do
        name = random_name
        new_folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => name }
        @test_folder.create_folder(new_folder_props)
        @test_folder.children.map(&:name).should include(name)
      end

      it "should create a folder using convenient method" do
        name = random_name
        @test_folder.create_cmis_folder(name)
        @test_folder.children.map(&:name).should include(name)
      end

      it "should create document" do
        content_stream = CMIS::create_content_stream(file_path("text_file.txt"), @session)
        text_file = random_name + ".txt"
        props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => text_file }
        id = @test_folder.create_document(props, content_stream, CMIS::VersioningState::MAJOR)
        doc = @session.get_object(id)
    
        doc.properties.each do |p|
          p.value.should == 16 if p.definition.id == "cmis:contentStreamLength"
        end
      end

      it "should create document using convenient method" do
        file = file_path("text_file.txt")
        file_name = random_name + ".txt"
        id = @test_folder.create_cmis_document(file_name, file)
        doc = @session.get_object(id)

        doc.properties.each do |p|
          p.value.should == 16 if p.definition.id == "cmis:contentStreamLength"
        end
      end

      it "should create document by specifying a string as content" do
        content = "Please, save me!"
        file_name = random_name + ".txt"
        id = @test_folder.create_text_doc(file_name, content)
        doc = @session.get_object(id)

        doc.properties.each do |p|
          p.value.should == content.size if p.definition.id == "cmis:contentStreamLength"
        end
      end

      it "should be possible to use multi-filing" do
        doc = create_random_doc(@test_folder)
        folder = @test_folder.create_cmis_folder("multi-filing")
        doc.add_to_folder(folder, true) # true means all versions
        doc.parents.size.should == 2
      end
    end

    describe "Updating objects" do
      it "should rename a document" do
        doc = create_random_doc(@test_folder)
        renamed_file_name = "renamed_" + doc.name
        props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", 
                  CMIS::PropertyIds::NAME => renamed_file_name }
        doc.update_properties(props)

        doc.name.should == renamed_file_name
      end

      it "should update the content of a document (versioning)" do
        doc = create_random_doc(@test_folder)
    
        content_stream = CMIS::create_content_stream(file_path("text_file2.txt"), @session)
        working_copy = @session.get_object(doc.check_out)
        id = working_copy.check_in(false, nil, content_stream, "minor version")
        doc = @session.get_object(id)
      
        doc.properties.each do |p|
          p.value.should == 17 if p.definition.id == "cmis:contentStreamLength"
          p.value.should == "1.1" if p.definition.id == "cmis:versionLabel"
        end

        versions = doc.all_versions
        versions.size.should == 2
      end
    end

    describe "Deleting objects" do
      it "should delete a document" do
        content_stream = CMIS::create_content_stream(file_path("text_file.txt"), @session)
        text_file = random_name + ".txt"
        props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document",
                CMIS::PropertyIds::NAME => text_file }
        id = @test_folder.create_document(props, content_stream, CMIS::VersioningState::MAJOR)

        doc = @session.get_object(id)
     
        doc.delete(true)
        children = @test_folder.children
        children.map(&:name).should_not include(text_file)
      end

      it "should delete a folder tree" do
        root = @test_folder
        random_folder_name = random_name
        folder1 = root.create_cmis_folder(random_folder_name)
        folder11 = folder1.create_cmis_folder("Folder11")
        folder12 = folder1.create_cmis_folder("Folder12")
        @test_folder.children.map(&:name).should include(random_folder_name)
        folder1.delete_tree(true, CMIS::UnfileObject::DELETE, true)
        @test_folder.children.map(&:name).should_not include(random_folder_name)
      end
    end

    describe "Querying and navigating objects" do
      it "should be possible to navigate through a folder tree" do
        root = @session.root_folder
        # just making sure it can be executed
        root.descendants(-1).count.should > 0 # get folders and documents
        root.folder_tree(-1).count.should > 0 # get folders only
      end

      it "should be possible to execute a simple query" do
        query = "SELECT cmis:name FROM cmis:folder WHERE cmis:name = 'Company Home'"
        q = @session.query(query, false)
      
        q.each do |result|
          result.get_property_value_by_query_name("cmis:name").should == "Company Home"
        end
      end

      it "should be possible to use paging" do
        @sub_folder = @test_folder.create_cmis_folder("Paging")

        5.times do
          @sub_folder.create_cmis_folder(random_name)
        end

        oc = CMIS::OperationContextImpl.new
        oc.max_items_per_page = 3
        @sub_folder.children(oc).skip_to(0).page.map(&:name).size.should == 3
        @sub_folder.children.map(&:name).size.should == 5
      end
    end

    describe "Access control" do
      it "should be possible to add acls to an object" do
        folder = @test_folder.create_cmis_folder("ACL test")
        oc = CMIS::OperationContextImpl.new
        oc.include_acls = true 
        folder = @session.get_object(folder, oc)
        original_acl_size = folder.acl.aces.size
        
        permissions = ["cmis:read"]
        principal = "guest"
        ace_in = @session.object_factory.create_ace(principal, permissions)
        folder.add_acl([ace_in], CMIS::AclPropagation::REPOSITORYDETERMINED)
        folder = @session.get_object(folder, oc)
        folder.acl.aces.size.should == original_acl_size + 2
      end
    end
  end

  describe "Local Alfresco" do
    atom_url = "http://localhost:8181/alfresco/service/cmis"
    user = "admin"
    password = "admin"

    it_behaves_like "a CMIS repository", atom_url, user, password
  end

  describe "Alfresco" do
    atom_url = "http://cmis.alfresco.com/cmisatom"
    user = "admin"
    password = "admin"
    
    #it_behaves_like "a CMIS repository", atom_url, user, password
  end

  describe "Nuxeo" do
    atom_url = "http://cmis.demo.nuxeo.org/nuxeo/atom/cmis"
    user = "Administrator"
    password = "Administrator"
    
    #it_behaves_like "a CMIS repository", atom_url, user, password
  end
end