raise "You need to run JRuby to use CMIS" unless RUBY_PLATFORM =~ /java/

require "cmis/version"
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

module CMIS
  # Your code goes here...
end
