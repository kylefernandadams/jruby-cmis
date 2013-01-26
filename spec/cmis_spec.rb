# encoding: utf-8

require 'spec_helper'

describe CMIS do  
  
  describe "Running against a local OpenCMIS InMemory Repository" do

    before(:all) do
      @atom_url = "http://localhost:8080/chemistry-opencmis-server-inmemory-0.8.0/atom"
      @user = "admin"
      @password = "admin"
      @repos = CMIS::repositories(@atom_url, @user, @password)
      @session = CMIS::create_session(@atom_url, @user, @password, @repos[0].get_id) 
    end

    it "should create a session" do
      @session.is_a?(Java::OrgApacheChemistryOpencmisClientRuntime::SessionImpl).should be_true
    end

    it "should retrieve all available repositories" do
      @repos.is_a?(Java::JavaUtil::ArrayList).should be_true
    end

    it "should have one repository with a name" do
      repo = @repos[0]
      repo.name.should == "Apache Chemistry OpenCMIS InMemory Repository"
    end

    it "should be possible to find the contents of the root folder" do
      root = @session.root_folder
      children = root.children
      children.map(&:name).should include("My_Document-0-0")
    end

    it "should create a folder object" do
      random_name = rand(8**8).to_s(8)
      new_folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => random_name }
      @session.root_folder.create_folder(new_folder_props)
      @session.root_folder.children.map(&:name).should include(random_name)
    end

    def content_as_string(stream)
      sb = java.lang.StringBuilder.new
      br = java.io.BufferedReader.new(java.io.InputStreamReader.new(stream.stream, "UTF-8"))
      line = br.read_line
      while line != nil do
        line = br.read_line
        sb.append(line)
      end

      br.close
      sb.to_s
    end

    def create_content_stream(filename)
      content = nil

      if filename != nil && filename.length > 0
        file = java.io.File.new(filename)
        stream = java.io.BufferedInputStream.new(java.io.FileInputStream.new(file))
        content = @session.object_factory.create_content_stream(file.name, file.length, CMIS::MimeTypes.getMIMEType(file), stream)
      end

      content
    end

    it "should create a simple document object" do
      content_stream = create_content_stream(file_path("text_file.txt"))
      text_file = rand(8**8).to_s(8) + ".txt"
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => text_file }
      id = @session.root_folder.create_document(props, content_stream, CMIS::VersioningState::NONE)
      
      # Let's read the content from the server
      doc = @session.get_object(id)
      content_from_server = content_as_string(doc.content_stream)
      
      puts "content from server: " + content_from_server.to_s  
    end

    it "should rename a document" do
      content_stream = create_content_stream(file_path("text_file.txt"))
      text_file = rand(8**8).to_s(8) + ".txt"
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document",
                CMIS::PropertyIds::NAME => text_file }
      id = @session.root_folder.create_document(props, content_stream, CMIS::VersioningState::NONE)

      doc = @session.get_object(id)
      renamed_text_file = "renamed_" + text_file
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", 
                CMIS::PropertyIds::NAME => renamed_text_file }
      
      doc.update_properties(props)

      doc.name.should == renamed_text_file
    end

    it "should update the content of a document" do
      pending "Load a freaking fixture!!"
    end

    it "should delete a document" do
      text_file = rand(8**8).to_s(8) + ".txt"
      mimetype = "text/plain; charset=UTF-8"
      content = java.lang.String.new("This is some test content.")
      buf = nil
      buf = content.getBytes("UTF-8")
      input = java.io.ByteArrayInputStream.new(buf)
      content_stream = @session.object_factory.create_content_stream(text_file, buf.length, mimetype, input)
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document",
                CMIS::PropertyIds::NAME => text_file }
      id = @session.root_folder.create_document(props, content_stream, CMIS::VersioningState::NONE)

      doc = @session.get_object(id)
     
      doc.delete(true)
      children = @session.root_folder.children
      children.map(&:name).should_not include(text_file)
    end

    it "should delete a folder tree" do
      root = @session.root_folder
      random_folder_name = rand(8**8).to_s(8)
      folder1 = root.create_folder({ CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => random_folder_name })
      folder11 = folder1.create_folder({ CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => "Folder11" })
      folder12 = folder1.create_folder({ CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => "Folder12" })
      @session.root_folder.children.map(&:name).should include(random_folder_name)
      folder1.delete_tree(true, CMIS::UnfileObject::DELETE, true)
      @session.root_folder.children.map(&:name).should_not include(random_folder_name)
    end

    it "should be possible to navigate through a folder tree" do
      root = @session.root_folder
      # just making sure it can be executed
      root.descendants(-1).count.should > 0 # get folders and documents
      root.folder_tree(-1).count.should > 0 # get folders only
    end
    
    it "should display the properties of an object" do
      props = @session.root_folder.properties   
      props.each do |p|
        disp_name = p.definition.display_name
        p.value_as_string.should == "/" if disp_name == "Path"
        p.value_as_string.should == "cmis:folder" if disp_name == "Type-Id"
        p.value_as_string.should == "Admin" if disp_name == "Created By"
        p.value_as_string.should == "RootFolder" if disp_name == "Name"
        p.value_as_string.should == "100" if disp_name == "Object Id"
        p.value_as_string.should be_nil if disp_name == "Parent Id"
      end
    end

    it "should be possible to get a property explicitly" do
      # A couple of folder specific props that we can access explicitly
      root = @session.root_folder
      root.is_root_folder.should == true
      root.path.should == "/"
    end

    it "should be possible to execute a simple query" do
      query = "SELECT * FROM cmis:document WHERE cmis:name LIKE 'My_Document-0-0'"
      q = @session.query(query, false)
      q.count.should == 1
      q.each do |result|
        result.property_by_query_name("cmis:name").first_value.should == "My_Document-0-0"
        result.property_by_query_name("cmis:objectTypeId").first_value.should == "ComplexType"
        result.property_by_query_name("cmis:contentStreamLength").first_value.should == "33401"
      end
    end

    it "should be possible to read the repository info" do
      rep_info = @session.repository_info
      cap = rep_info.capabilities

      # Just testing a few of them
      cap.is_get_descendants_supported.should == true
      cap.is_get_folder_tree_supported.should == true
      cap.get_changes_capability.value.should == "none"
      cap.get_query_capability.value.should == "bothcombined"
      cap.get_join_capability.value.should == "none"
    end
  end
end