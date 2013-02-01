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
      @model.session.repository_info.name.should == "Main Repository"
    end

    it "should override the default session" do
      pending
    end
  end

end