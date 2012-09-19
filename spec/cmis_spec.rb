# encoding: utf-8

require 'spec_helper'

describe CMIS do  
  
  describe "Running against Public OpenCMIS InMemory Repository" do
    it "should create a session" do
      session = CMIS::create_session("http://repo.opencmis.org/inmemory/atom/", "admin", "admin", "A1")
      session.respond_to?('get_repository_info').should be_true
    end

    it "should retrieve all available repositories" do
      repos = CMIS::repositories("http://repo.opencmis.org/inmemory/atom/", "admin", "admin")
      repos.is_a?(Java::JavaUtil::ArrayList).should be_true
    end

    it "should have one repository with an id and name" do
      repos = CMIS::repositories("http://repo.opencmis.org/inmemory/atom/", "admin", "admin")
      repo = repos[0]
      repo.get_name.should == "Apache Chemistry OpenCMIS InMemory Repository"
      repo.get_id.should == "A1"
    end

    it "should be possible to find the contents of the root folder" do
      session = CMIS::create_session("http://repo.opencmis.org/inmemory/atom/", "admin", "admin", "A1")
      root = session.get_root_folder
      children = root.get_children

      children.each do |o|
        puts o.get_name + " which is of type " + o.get_type.get_display_name
      end

      pending
    end

    it "should create a folder object" do
      pending
    end

    it "should create a simple document object" do
      pending
    end

    it "should read the contents of a document object" do
      pending
    end

    it "should update a document" do
      pending
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
