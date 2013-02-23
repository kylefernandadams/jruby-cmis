module CMIS
  FolderImpl = org.apache.chemistry.opencmis.client.runtime.FolderImpl
  DocumentImpl = org.apache.chemistry.opencmis.client.runtime.DocumentImpl
  
  # Explanation: https://github.com/jruby/jruby/wiki/Persistence
  DocumentImpl.__persistent__ = true
  FolderImpl.__persistent__ = true
  
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
      content = CMIS::create_content_stream(filename, session)
      doc_props = { PropertyIds::OBJECT_TYPE_ID => "cmis:document", PropertyIds::NAME => name }
      doc_props.merge!(props) if props != nil && props.is_a?(Hash)
      self.create_document(java.util.HashMap.new(doc_props), content, VersioningState::MAJOR)
    end

    def create_text_doc(name, content)
      FileUtils.create_text_document(self.id, name, content, "cmis:document", VersioningState::MAJOR, session)
    end

    def allowed_actions
      self.allowable_actions.allowable_actions.to_a
    end
  end
end
  