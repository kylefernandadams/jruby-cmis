module CMIS
  def self.create_session(url, user, password, repo_id = nil)
    session_factory = SessionFactoryImpl.new_instance
    params = session_params(url, user, password)
    repo_id = self.repositories(url, user, password)[0].id if repo_id == nil
    params[SessionParameter::REPOSITORY_ID] = repo_id
    session_factory.create_session(java.util.HashMap.new(params))
  end

  def self.repositories(url, user, password)
    session_factory = SessionFactoryImpl.new_instance
    params = session_params(url, user, password)
    session_factory.get_repositories(java.util.HashMap.new(params))
  end

  def self.create_content_stream(filename, session)
    file = java.io.File.new(filename)
    file_input_stream = java.io.FileInputStream.new(file)
    stream = java.io.BufferedInputStream.new(file_input_stream)
    content = session.object_factory.create_content_stream(file.name, file.length, MimeTypes.getMIMEType(file), stream)
    
    content
  end

  private
  
  def self.session_params(url, user, password)
    params = { 
      SessionParameter::ATOMPUB_URL => url,
      SessionParameter::BINDING_TYPE => BindingType::ATOMPUB.value,
      SessionParameter::USER => user,
      SessionParameter::PASSWORD => password
    }
    
    params
  end
end