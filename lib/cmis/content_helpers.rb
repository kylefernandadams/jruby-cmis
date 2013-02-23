module CMIS
  def self.create_content_stream(filename, session)
    file = java.io.File.new(filename)
    file_input_stream = java.io.FileInputStream.new(file)
    stream = java.io.BufferedInputStream.new(file_input_stream)
    content = session.object_factory.create_content_stream(file.name, file.length, MimeTypes.getMIMEType(file), stream)
    
    content
  end
end