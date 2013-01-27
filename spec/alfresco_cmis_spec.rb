require 'spec_helper'

describe "Alfresco CMIS" do
  
  before(:all) do
    @atom_url = "http://127.0.0.1:8181/alfresco/cmisatom"
    @user = "admin"
    @password = "admin"
    @repos = CMIS::repositories(@atom_url, @user, @password)
    @session = CMIS::create_session(@atom_url, @user, @password, @repos[0].id)
    @test_folder = @session.root_folder.create_cmis_folder("JRUBY_CMIS_TEST") 
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
      repo.name.should == "Main Repository"
    end

    it "should be possible to read the repository info" do
      rep_info = @session.repository_info
      cap = rep_info.capabilities

      # Just testing a few of them
      cap.is_get_descendants_supported.should == true
      cap.is_get_folder_tree_supported.should == true
      cap.changes_capability.value.should == "none"
      cap.query_capability.value.should == "bothcombined"
      cap.join_capability.value.should == "none"
    end
  end

  describe "Reading objects" do
    it "should be possible to find the contents of the root folder" do
      root = @session.root_folder
      children = root.children
      children.map(&:name).should include("Data Dictionary")
    end

    it "should display the properties of an object" do
      props = @session.root_folder.properties   
      props.each do |p|
        disp_name = p.definition.display_name
        p.value_as_string.should == "/" if disp_name == "Path"
        p.value_as_string.should == "cmis:folder" if disp_name == "Type-Id"
        p.value_as_string.should == "Admin" if disp_name == "Created By"
        p.value_as_string.should == "Company Home" if disp_name == "Name"
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
      content_stream = CMIS::create_content_stream(file_path("text_file.txt"), @session)
      text_file = random_name + ".txt"
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => text_file }
      id = @test_folder.create_document(props, content_stream, CMIS::VersioningState::MAJOR)
      doc = @session.get_object(id)
      doc.type.is_versionable.should == true
    end

    it "should be possible to check if a document is versionable" do
      file = file_path("text_file.txt")
      name = random_name + ".txt"
      id = @test_folder.create_cmis_document(name, file)
      doc = @session.get_object(id)
      doc.type.is_versionable.should == true
    end
  end

  describe "Writing objects" do
    # TODO: before all: create a folder to put in the shit
    # TODO: Clean up the mess afterwards

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
      #puts doc.inspect # Do something here
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
  end

  describe "Updating objects" do
    it "should rename a document" do
      file = file_path("text_file.txt")
      file_name = random_name + ".txt"
      id = @test_folder.create_cmis_document(file_name, file)

      doc = @session.get_object(id)
      renamed_file_name = "renamed_" + file_name
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", 
                CMIS::PropertyIds::NAME => renamed_file_name }
      doc.update_properties(props)

      doc.name.should == renamed_file_name
    end

    it "should update the content of a document (versioning)", focus: true do
      file = file_path("text_file.txt")
      file_name = random_name + ".txt"
      id = @test_folder.create_cmis_document(file_name, file)
      doc = @session.get_object(id)
    
      content_stream = CMIS::create_content_stream(file_path("text_file2.txt"), @session)
      working_copy = @session.get_object(doc.check_out)
      id = working_copy.check_in(false, nil, content_stream, "minor version")
      doc = @session.get_object(id)
    
      doc.properties.each do |p|
        p.value.should == 17 if p.definition.id == "cmis:contentStreamLength"
      end

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
  end

end
