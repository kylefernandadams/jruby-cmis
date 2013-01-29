raise "You need to run JRuby to use CMIS" unless RUBY_PLATFORM =~ /java/

require "cmis/version"
require 'java' 

Dir[File.join(File.dirname(__FILE__), "../target/dependency/*.jar")].each do |jar|
  require jar
end

module CMIS
  import org.apache.chemistry.opencmis.client.api.Session
  import org.apache.chemistry.opencmis.client.api.SessionFactory
  import org.apache.chemistry.opencmis.client.api.OperationContext
  import org.apache.chemistry.opencmis.client.util.FileUtils
  import org.apache.chemistry.opencmis.client.runtime.OperationContextImpl
  import org.apache.chemistry.opencmis.client.runtime.SessionFactoryImpl
  import org.apache.chemistry.opencmis.commons.SessionParameter
  import org.apache.chemistry.opencmis.commons.PropertyIds
  import org.apache.chemistry.opencmis.commons.impl.MimeTypes
  import org.apache.chemistry.opencmis.commons.data.AclCapabilities
  
  import org.apache.chemistry.opencmis.commons.enums.Action
  import org.apache.chemistry.opencmis.commons.enums.AclPropagation
  import org.apache.chemistry.opencmis.commons.enums.BaseTypeId
  import org.apache.chemistry.opencmis.commons.enums.CapabilityAcl
  import org.apache.chemistry.opencmis.commons.enums.VersioningState
  import org.apache.chemistry.opencmis.commons.enums.UnfileObject
  import org.apache.chemistry.opencmis.commons.enums.BindingType
  import org.apache.chemistry.opencmis.commons.enums.CapabilityChanges
  import org.apache.chemistry.opencmis.commons.enums.CapabilityContentStreamUpdates
  import org.apache.chemistry.opencmis.commons.enums.CapabilityJoin
  import org.apache.chemistry.opencmis.commons.enums.CapabilityQuery
  import org.apache.chemistry.opencmis.commons.enums.CapabilityRenditions
  import org.apache.chemistry.opencmis.commons.enums.Cardinality
  import org.apache.chemistry.opencmis.commons.enums.ChangeType
  import org.apache.chemistry.opencmis.commons.enums.ContentStreamAllowed
  import org.apache.chemistry.opencmis.commons.enums.DateTimeResolution
  import org.apache.chemistry.opencmis.commons.enums.DecimalPrecision
  import org.apache.chemistry.opencmis.commons.enums.ExtensionLevel
  import org.apache.chemistry.opencmis.commons.enums.IncludeRelationships
  import org.apache.chemistry.opencmis.commons.enums.PropertyType
  import org.apache.chemistry.opencmis.commons.enums.RelationshipDirection
  import org.apache.chemistry.opencmis.commons.enums.SupportedPermissions
  import org.apache.chemistry.opencmis.commons.enums.UnfileObject
  import org.apache.chemistry.opencmis.commons.enums.Updatability

  FolderImpl = org.apache.chemistry.opencmis.client.runtime.FolderImpl
  DocumentImpl = org.apache.chemistry.opencmis.client.runtime.DocumentImpl
  
  class DocumentImpl
    def download(destination_path)
      FileUtils.download(self, destination_path)
    end

    def allowed_actions
      self.allowable_actions.allowable_actions.to_a
    end
  end
  
  class FolderImpl
    def create_cmis_folder(name, props = nil)
      folder_props = { PropertyIds::OBJECT_TYPE_ID => "cmis:folder", PropertyIds::NAME => name }
      folder_props.merge!(props) if props != nil && props.is_a?(Hash)
      self.create_folder(java.util.HashMap.new(folder_props))
    end

    def create_cmis_document(name, filename, props = nil)
      if filename != nil && filename.length > 0
        file = java.io.File.new(filename)
        stream = java.io.BufferedInputStream.new(java.io.FileInputStream.new(file))
        content = session.object_factory.create_content_stream(file.name, file.length, CMIS::MimeTypes.getMIMEType(file), stream)
        doc_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => name }
        doc_props.merge!(props) if props != nil && props.is_a?(Hash)
        self.create_document(doc_props, content, CMIS::VersioningState::MAJOR)
      end
    end

    def create_text_doc(name, content)
      FileUtils.create_text_document(self.id, name, content, "cmis:document", CMIS::VersioningState::MAJOR, session)
    end

    def allowed_actions
      self.allowable_actions.allowable_actions.to_a
    end
  end

  def self.create_session(url, user, password, repo_id = nil)
      session_factory = SessionFactoryImpl.new_instance
      repo_id = self.repositories(url, user, password)[0].id if repo_id == nil
      
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

  def self.create_content_stream(filename, session)
    content = nil

    if filename != nil && filename.length > 0
      file = java.io.File.new(filename)
      stream = java.io.BufferedInputStream.new(java.io.FileInputStream.new(file))
      content = session.object_factory.create_content_stream(file.name, file.length, CMIS::MimeTypes.getMIMEType(file), stream)
    end

    content
  end
end