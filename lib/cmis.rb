raise "You need to run JRuby to use CMIS" unless RUBY_PLATFORM =~ /java/

require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

require 'cmis/version'
require 'cmis/imports'
require 'cmis/object_impl'
require 'cmis/helpers'