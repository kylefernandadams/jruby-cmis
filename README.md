# Cmis

A JRuby thin wrapper for the Apache Chemistry OpenCMIS Java libraries.

More information about Apache Chemistry can be found here: http://chemistry.apache.org/

## Installation

Add this line to your application's Gemfile:

    gem 'cmis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cmis

## Usage

This guide is for JRuby developers who want to access CMIS-compliant content repositories from JRuby. The examples has been written to work with Alfresco Community Edition 4.2.c which is one of the most feature complete CMIS content repository. If you want to test the code snippets below you have to download and install Alfresco. You can find the version that fits your platform here: http://wiki.alfresco.com/wiki/Download_and_Install_Alfresco

## Connecting to a CMIS repository

To be able to do anything useful on a CMIS repository, you must first find a repository, and create a session with it:

```ruby

atom_url = "http://localhost:8181/alfresco/service/cmis"
user = "admin"
password = "admin"
@session = CMIS::create_session(atom_url, user, password)

```
Most CMIS servers only provides one repository by default that you can connect to and the code above automatically connects to the first repository that it finds.
If you want to connect to a specific repository you can do it like this:

```ruby
available_repos = CMIS::repositories(atom_url, user, password)
puts "Trying to connect to a repository with id #{available_repos[0].id}"
@session = CMIS::create_session(atom_url, user, password, available_repos[0].id)

```

## Working with folders and documents

Finding the contents of the root folder:

```ruby
root = @session.root_folder
children = root.children

children.each do |o|
  puts o.name # Prints out all children objects found in the root folder 
end
```

### Creating folders

Create a folder the simple way. This is a convenient method implemented in the JRuby CMIS library.

```ruby
root.create_cmis_folder("My new folder")
```

Create a folder the hard way:

```ruby
folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => "Another folder" }
root.create_folder(folder_props)
```

### Creating/Uploading documents

#### Create a document object the simple way. 

This is a convenient method implemented in the JRuby CMIS Library.
This method takes a name and a file path and uploads the file to the repository. The document will be saved as a major version.

```ruby
id = root.create_cmis_document("cmis_logo.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts doc.name
```

#### Create a document object the hard way:
# TODO

#### Download a document to your local disk:
# TODO

### Updating a document

```ruby
id = root.create_cmis_document("cmis_logo_original.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts "Original name: #{doc.name}"
props = { CMIS::PropertyIds::NAME => "cmis_logo_renamed.png"}
id = doc.update_properties(props)
doc = @session.get_object(id)
puts "New name: #{doc.name}"
```

### Deleting a document

```ruby
doc = @session.get_object(id)
doc.delete # Yay, that was easy!
```

### Deleting a folder tree

```ruby
# First we need to create a folder tree
folder1 = root.create_cmis_folder("folder1")
folder11 = folder1.create_cmis_folder("Folder11")
folder12 = folder1.create_cmis_folder("Folder12")
# Delete it
folder1.delete_tree(true, CMIS::UnfileObject::DELETE, true) # parameter explanation: boolean allversions, UnfileObject unfile, boolean continueOnFailure
```

## Working with CMIS Properties

```ruby
### Displaying the properties of an object
props = @session.root_folder.properties
props.each do |p|
  display_name = p.definition.display_name
  value = p.value_as_string
  if display_name != nil && value != nil
    puts p.definition.display_name + ": " + p.value_as_string
  end
end
```

### Getting a property explicitly

Each object type has a known set of properties, and you can retrieve these explicitly. For example, the document type has a set of properties described by the DocumentProperties interface (http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/DocumentProperties.html), and you can use the methods on this interface to retrieve the value a property.

```ruby
# For root folder
puts "Is root folder? " + root.is_root_folder.to_s
puts "Path: " + root.path

# For a document
id = root.create_cmis_document("cmis_logo_original.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts "Name: " + doc.name
puts "Version label: " + doc.version_label
puts "Content stream file name: " + doc.content_stream_file_name
puts "Content stream mime type: " + doc.content_stream_mime_type
```

### Working with CMIS Queries.
```ruby
query = "SELECT * FROM cmis:document WHERE cmis:name LIKE 'cmis%'"
q = @session.query(query, false) # true means search all versions

q.each do |result|
  puts result.property_value_by_query_name("cmis:name").inspect
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
