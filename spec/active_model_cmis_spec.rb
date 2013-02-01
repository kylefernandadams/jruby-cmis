require 'spec_helper'
require 'test/unit/assertions'

class CompliantModel < CMIS::Model::Document
end


describe CMIS::Model::Document do
  include Test::Unit::Assertions
  include ActiveModel::Lint::Tests

  before :each do
    @model = CompliantModel.new
  end

  def model
    @model
  end

  describe "active model lint tests" do
    ActiveModel::Lint::Tests.public_instance_methods.map{|m| m.to_s}.grep(/^test/).each do |m|
      example m.gsub('_',' ') do
        send m
      end
    end
  end
  
end