raise "You need to run JRuby to use CMIS" unless RUBY_PLATFORM =~ /java/

require "cmis/version"
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

module CMIS
  import org.apache.chemistry.opencmis.client.api.Session
  import org.apache.chemistry.opencmis.client.api.SessionFactory
  import org.apache.chemistry.opencmis.client.runtime.SessionFactoryImpl
  import org.apache.chemistry.opencmis.commons.enums.BindingType
  import org.apache.chemistry.opencmis.commons.SessionParameter
  import org.apache.chemistry.opencmis.commons.PropertyIds
  import org.apache.chemistry.opencmis.commons.enums.VersioningState
    
  def self.create_session(url, user, password, repo_id)
      session_factory = SessionFactoryImpl.new_instance
      parameters = { 
        SessionParameter::ATOMPUB_URL => url,
        SessionParameter::BINDING_TYPE => BindingType::ATOMPUB.value,
        SessionParameter::USER => user,
        SessionParameter::PASSWORD => password,
        SessionParameter::REPOSITORY_ID => repo_id
      }

      session_factory.create_session(parameters)
  end

  def self.repositories(url, user, password)
    session_factory = SessionFactoryImpl.new_instance
      parameters = { 
        SessionParameter::ATOMPUB_URL => url,
        SessionParameter::BINDING_TYPE => BindingType::ATOMPUB.value,
        SessionParameter::USER => user,
        SessionParameter::PASSWORD => password
      }

    session_factory.get_repositories(parameters)
  end

end
