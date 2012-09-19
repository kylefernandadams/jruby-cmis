# encoding: utf-8

require 'spec_helper'

describe CMIS do  
  
  describe "Running against a local OpenCMIS InMemory Repository" do

    before(:all) do
      @atom_url = "http://localhost:8080/opencmis-inmemory/atom"
      @user = "admin"
      @password = "admin"
      @repo = "A1"
      @session = CMIS::create_session(@atom_url, @user, @password, @repo) 
      @repos = CMIS::repositories(@atom_url, @user, @password)
    end

    it "should create a session" do
      @session.respond_to?('get_repository_info').should be_true
    end

    it "should retrieve all available repositories" do
      @repos.is_a?(Java::JavaUtil::ArrayList).should be_true
    end

    it "should have one repository with an id and name" do
      @repos = CMIS::repositories(@atom_url, @user, @password)
      repo = @repos[0]
      repo.get_name.should == "Apache Chemistry OpenCMIS InMemory Repository"
      repo.get_id.should == @repo
    end

    it "should be possible to find the contents of the root folder" do
      @session = CMIS::create_session(@atom_url, @user, @password, @repo)
      root = @session.get_root_folder
      children = root.get_children
      children.map(&:get_name).should include("My_Document-0-0")
    end

    it "should create a folder object" do
      random_name = rand(8**8).to_s(8)
      new_folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => random_name }
      @session.get_root_folder.create_folder(new_folder_props)
      @session.get_root_folder.get_children.map(&:get_name).should include(random_name)
    end

    def content_as_string(stream)
      sb = java.lang.StringBuilder.new
      br = java.io.BufferedReader.new(java.io.InputStreamReader.new(stream.get_stream, "UTF-8"))
      line = br.read_line
      while line != nil do
        line = br.read_line
        sb.append(line)
      end

      br.close
      puts sb.to_s
      sb.to_s
    end

    it "should create a simple document object" do
      pending

      text_file = rand(8**8).to_s(8) + ".txt"
      mimetype = "text/plain; charset=UTF-8"
      content = java.lang.String.new("This is some test content.")
      buf = nil
      buf = content.getBytes("UTF-8")
      input = java.io.ByteArrayInputStream.new(buf)
      content_stream = @session.get_object_factory.create_content_stream(text_file, buf.length, mimetype, input)
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => text_file }
      id = @session.get_root_folder.create_document(props, content_stream, CMIS::VersioningState::NONE)
      
      # Let's read the content from the server
      doc = @session.get_object(id)
      content_from_server = content_as_string(doc.get_content_stream)
      
      puts "content: " + content.to_s
      puts "content from server: " + content_from_server.to_s
      
      content.to_s.should == content_from_server
    end

    it "should update a document" do
      text_file = rand(8**8).to_s(8) + ".txt"
      mimetype = "text/plain; charset=UTF-8"
      content = java.lang.String.new("This is some test content.")
      buf = nil
      buf = content.getBytes("UTF-8")
      input = java.io.ByteArrayInputStream.new(buf)
      content_stream = @session.get_object_factory.create_content_stream(text_file, buf.length, mimetype, input)
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document",
                CMIS::PropertyIds::NAME => text_file }
      id = @session.get_root_folder.create_document(props, content_stream, CMIS::VersioningState::NONE)

      doc = @session.get_object(id)        
      props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", 
                CMIS::PropertyIds::NAME => "renamed_" + text_file }
      id = doc.update_properties(props)

      doc.get_name.should == "renamed" + text_file
    end

    it "should delete a document" do
      pending
    end

    it "should delete a folder tree" do
      pending
    end

    it "should be possible to navigate through a folder tree" do
      pending
    end
    
    it "should display the properties of an object" do
      pending
    end

    it "should be possible to get a property explicitly" do
      pending
    end

    it "should be possible to get a property value by id" do
      pending
    end

    it "should be possible to get a property value by query name" do
      pending
    end

    it "should be possible to execute a simple query" do
      pending
    end
  end
end