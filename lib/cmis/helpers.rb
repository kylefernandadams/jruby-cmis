module CMIS
  def self.create_session(url, user, password, repo_id = nil)
      session_factory = SessionFactoryImpl.new_instance
      repo_id = self.repositories(url, user, password)[0].id if repo_id == nil
      
      params = { 
        SessionParameter::ATOMPUB_URL => url,
        SessionParameter::BINDING_TYPE => BindingType::ATOMPUB.value,
        SessionParameter::USER => user,
        SessionParameter::PASSWORD => password,
        SessionParameter::REPOSITORY_ID => repo_id
      }

      session_factory.create_session(java.util.HashMap.new(params))
  end

  def self.create_session_with_soap(user, password, web_services, repo_id = nil)
    session_factory = SessionFactoryImpl.new_instance
    repo_id = self.repositories(url, user, password)[0].id if repo_id == nil
    
    params = {
        SessionParameter::BINDING_TYPE => BindingType::WEBSERVICES.value,
        SessionParameter::USER => user,
        SessionParameter::PASSWORD => password,
        SessionParameter::REPOSITORY_ID => repo_id
    }.merge!(web_services)

    session_factory.create_session(java.util.HashMap.new(params))
  end

  def self.repositories(url, user, password)
    session_factory = SessionFactoryImpl.new_instance
      params = { 
        SessionParameter::ATOMPUB_URL => url,
        SessionParameter::BINDING_TYPE => BindingType::ATOMPUB.value,
        SessionParameter::USER => user,
        SessionParameter::PASSWORD => password
      }

    session_factory.get_repositories(java.util.HashMap.new(params))
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