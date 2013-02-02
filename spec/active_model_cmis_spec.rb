require 'spec_helper'
require 'test/unit/assertions'

class CompliantModel < CMIS::Model::Document
end

describe CMIS::Model::Document do
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  before :each do
    @session = CMIS::create_session("http://localhost:8181/alfresco/service/cmis", "admin", "admin")
    CompliantModel.session = @session
    @model = CompliantModel.new
  end

  def model
    @model
  end

  describe "ActiveModel Lint Tests" do
    ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
      example m.gsub('_',' ') do
        send m
      end
    end
  end

  describe "instance repository session" do
    it "should use the default session" do
      @model.session.should == @session
    end

    it "should have a session" do
      @model.session.should be_instance_of(Java::OrgApacheChemistryOpencmisClientRuntime::SessionImpl)
    end
  end

  # Remember parent, name, type
  describe "a new model" do
    it "should be a new document" do
      doc = CompliantModel.new
      doc.id.should be_nil
      doc.cmis_type.should == "cmis:document"
      doc.name.should == nil
      doc.parent.should == nil
      doc.should be_new
      doc.should be_new_document
      doc.should be_new_record
    end

    it "should only set predefined attributes" do
      doc = CompliantModel.new(name: "test", parent: "id12345", cmis_type: "cmis:custom_document", hoho: "hehe")
      doc.name.should == "test"
      doc.parent.should == "id12345"
      doc.cmis_type.should == "cmis:custom_document"
    end
  end
end