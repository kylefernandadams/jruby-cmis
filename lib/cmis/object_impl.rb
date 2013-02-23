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
      if filename != nil && filename.length > 0
        file = java.io.File.new(filename)
        stream = java.io.BufferedInputStream.new(java.io.FileInputStream.new(file))
        content = session.object_factory.create_content_stream(file.name, file.length, CMIS::MimeTypes.getMIMEType(file), stream)
        doc_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => name }
        doc_props.merge!(props) if props != nil && props.is_a?(Hash)
        self.create_document(java.util.HashMap.new(doc_props), content, CMIS::VersioningState::MAJOR)
      end
    end

    def create_text_doc(name, content)
      FileUtils.create_text_document(self.id, name, content, "cmis:document", CMIS::VersioningState::MAJOR, session)
    end

    def allowed_actions
      self.allowable_actions.allowable_actions.to_a
    end
  end
end
  