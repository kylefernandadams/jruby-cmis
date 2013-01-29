# CMIS

CMIS client for JRuby. This gem uses the Apache Chemistry OpenCMIS Java libraries under the hood.

More information about Apache Chemistry can be found here: http://chemistry.apache.org/

## What is CMIS

Content Management Interoperability Services (CMIS) is an open standard that defines an abstraction layer for controlling diverse document management systems and repositories using web protocols. CMIS defines a domain model plus Web Services and Restful AtomPub (RFC5023) bindings that can be used by applications.

Here are a few CMIS-compliant content repositories:

* [Alfresco](http://www.alfresco.com)
* [Nuxeo](http://www.nuxeo.com)
* [EMC Documentum](http://www.emc.com/domains/documentum/index.htm)
* [Sharepoint](http://sharepoint.microsoft.com/en-us/Pages/default.aspx)
* [IBM FileNet Content Manager](http://www-01.ibm.com/software/data/content-management/filenet-content-manager/)
* [KnowledgeTree](https://www.knowledgetree.com/)

## Installation

Add this line to your application's Gemfile:

    gem 'cmis'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cmis


## Notes about JRuby and OpenCMIS
Every call you do in this library that returns an object actually returns a real Java object from OpenCMIS so you have access to all the functionality that OpenCMIS provides.

If you want to do something that is not described in the documentation below you can read the [OpenCMIS JavaDoc](http://chemistry.apache.org/java/0.8.0/maven/apidocs/) and you should figure out how to do it.

## Usage

This guide is for JRuby developers who want to access CMIS-compliant content repositories from JRuby. The examples has been tested with Alfresco Community Edition 4.2.c which is one of the most feature complete CMIS content repository.

If you want to run the code snippets below you can download and install Alfresco. You can find the version that fits your platform here: http://wiki.alfresco.com/wiki/Download_and_Install_Alfresco

You can also run the examples using the Public Alfresco CMIS server. More information can be found here: http://cmis.alfresco.com. The atom url for the public 
server is http://cmis.alfresco.com/cmisatom.

Nuxeo also provides a demo server. More information can be found here: http://doc.nuxeo.com/display/NXDOC/CMIS+for+Nuxeo#CMISforNuxeo-Onlinedemo .

The documentation below is heavily based on the [OpenCMIS Client API Developer's Guide](http://chemistry.apache.org/java/developing/guide.html)

## Connecting to a CMIS repository

To be able to do anything useful on a CMIS repository, you must first find a repository, and create a session with it:

```ruby
require 'cmis'
atom_url = "http://localhost:8080/alfresco/service/cmis"
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

Note: The create_session method returns a real [Session](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/Session.html) object that is used in OpenCMIS so you have access to every functionality that the Session object provides.

## Working with folders and documents

Finding the contents of the root folder:

```ruby
root = @session.root_folder
children = root.children

# Prints out all children objects name found in the root folder
children.each do |o|
  puts o.name
end
```

### Creating folders

Create a folder the simple way. The create_cmis_folder method is a convenient method implemented in the JRuby CMIS library.

```ruby
root.create_cmis_folder("My new folder")
```

Create a folder the hard way:

```ruby
folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:folder", CMIS::PropertyIds::NAME => "Another folder" }
root.create_folder(folder_props)
puts folder.name
```

Note: When you create a folder it will return an actual Java OpenCMIS Folder object. That means you have access to everything it provides. [More information can be found in the JavaDoc for the Folder interface](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/Folder.html)

### Creating/Uploading documents

The create_cmis_document method is a convenient method implemented in the JRuby CMIS Library.
This method takes a name and a file path and uploads the file to the repository. The document will be saved as a major version.

```ruby
id = root.create_cmis_document("cmis_logo.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts doc.name
```

#### Create a document the hard way (but with more flexibility)

```ruby
content_stream = CMIS::create_content_stream("/Users/ricn/cmis_logo.png", @session)
props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "cmis:document", CMIS::PropertyIds::NAME => "cmis_logo.png" }
id = root.create_document(props, content_stream, CMIS::VersioningState::MAJOR)
doc = @session.get_object(id)
puts doc.name
```

Note: When you create a docuemtn it will return an actual Java OpenCMIS Document object. That means you have access to everything it provides. [More information can be found in the JavaDoc for the Document interface](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/Document.html)

#### Download a document to your local disc

```ruby
doc = @session.get_object(id)
file = "/Users/ricn/" + doc.name
doc.download(file)
```

### Updating a document

Updating metadata:

```ruby
id = root.create_cmis_document("cmis_logo_original.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts "Original name: #{doc.name}"
props = { CMIS::PropertyIds::NAME => "cmis_logo_renamed.png"}
id = doc.update_properties(props)
doc = @session.get_object(id)
puts "New name: #{doc.name}"
```

Updating the actual content of a document (using check out / check in):
```ruby
root = @session.root_folder
doc = root.create_text_doc("my_file.txt", "content")
puts "Orginal version: " + doc.version_label
id = doc.check_out
working_copy = @session.get_object(id)

content_stream = CMIS::create_content_stream("/Users/ricn/updated_file.txt", @session)

# check_in parameters: boolean major, properties, contentStream, checkinComment
id = working_copy.check_in(false, nil, content_stream, "minor version")
doc = @session.get_object(id)

puts "New version: " + doc.version_label
```

Update the content of a document directly:

TODO

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

# Parameter: boolean allversions, UnfileObject unfile, boolean continueOnFailure
folder1.delete_tree(true, CMIS::UnfileObject::DELETE, true)
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

Each object type has a known set of properties, and you can retrieve these explicitly. For example, the document type has a set of properties described by the [DocumentProperties](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/DocumentProperties.html) interface, and you can use the methods on this interface to retrieve the value a property.

```ruby
# For root folder
puts "Is root folder? " + root.is_root_folder.to_s
puts "Path: " + root.path

# For a document
id = root.create_cmis_document("cmis.png", "/Users/ricn/cmis_logo.png")
doc = @session.get_object(id)
puts "Name: " + doc.name
puts "Version label: " + doc.version_label
puts "Content stream file name: " + doc.content_stream_file_name
puts "Content stream mime type: " + doc.content_stream_mime_type
```

Get allowed actions for a document or folder:

```ruby
root = @session.root_folder
allowed_actions = root.allowed_actions

allowed_actions.each do |a|
  puts a.to_s + " is an allowed action on " + root.name
end
```

A complete list of actions can be found here: http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/commons/enums/Action.html

## Working with CMIS Queries

```ruby
query = "SELECT * FROM cmis:folder"
q = @session.query(query, false) # false means only latest versions

q.each do |result|
  props = result.properties
  props.each do |p|
    disp_name = p.display_name
    puts "Name: " + p.first_value if disp_name == "Name"
  end
end
```

## Capabilities
CMIS repositories has different capabilities. Some are designed for a specific application domain and do not provide capabilities that are not needed for that domain. This means a repository implementation may not be able to support all the capabilities that the CMIS specification provides. To allow this, some capabilities can be optionally supported by a CMIS repository.

This is how you check the capabilites of the repository:

```ruby
rep_info = @session.repository_info
cap = rep_info.capabilities

puts "Navigation Capabilities"
puts "Get descendants supported: " + cap.is_get_descendants_supported.to_s
puts "Get folder tree supported: " + cap.is_get_folder_tree_supported.to_s
puts "=============================="
puts "Object Capabilities"
puts "Content Stream: " + cap.content_stream_updates_capability.value
puts "Changes: " + cap.changes_capability.value
puts "Renditions: " + cap.renditions_capability.value 
puts "=============================="
puts "Filing Capabilities"
puts "Multifiling supported: " + cap.is_multifiling_supported.to_s
puts "Unfiling supported: " + cap.is_unfiling_supported.to_s
puts "Version specific filing supported: " + cap.is_version_specific_filing_supported.to_s
puts "=============================="
puts "Versioning Capabilities"
puts "PWC searchable: " + cap.is_pwc_searchable_supported.to_s
puts "PWC updatable: " + cap.is_pwc_updatable_supported.to_s
puts "All versions searchable: " + cap.is_all_versions_searchable_supported.to_s
puts "=============================="
puts "Query Capabilities"
puts "Query: " + cap.query_capability.value
puts "Join: " + cap.join_capability.value
puts "=============================="
puts "ACL Capabilities"
puts "ACL: " + cap.acl_capability.value
```

## Paging
When you retrieve the children of a CMIS object, the result set returned is of an arbitrary size. Retrieving a large result set synchronously could increase response times. To improve performance, you can use OpenCMIS's paging support to control the size of the result set retrieved from the repository. To use paging, 
you must specify an [OperationContext](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/client/api/OperationContext.html) when invoking children method call on the parent object. The OperationContext specifies the maximum number of items to retrieve in a page.

```ruby
root = @session.root_folder
oc = CMIS::OperationContextImpl.new
oc.max_items_per_page = 3

# List all object in the root folder using paging
page1 = root.children(oc).skip_to(0).page.map(&:name)
page2 = root.children(oc).skip_to(1).page.map(&:name)

puts "Page 1:"
page1.each do |o|
  puts o
end

puts "Page 2:"
page2.each do |o|
  puts o
end
```

## Renditions

Some repositories provide a facility to retrieve alternative representations, or renditions of a document. An example is a preview thumbnail image of the content of a document, which could be presented to the user without needing to download the full document content. Another example is a PDF version of a word document.

A CMIS repository may have zero or more renditions for a document or folder in addition to the document's content stream.
At present the CMIS specification only allows renditions to be read. There are no facilities to create, update or delete renditions. Renditions are of a specific version of the document and may differ between document versions. Each rendition consists of a set of rendition attributes and a rendition stream. Rendition attributes are not object properties, and are not queryable. Renditions can be retrieved using the getRenditions service.

```ruby
puts "Rendition support: " + @session.repository_info.capabilities.renditions_capability.to_s

id = @session.root_folder.create_text_doc("simple file.txt", "My content")
context = @session.create_operation_context
context.rendition_filter_string = "cmis:thumbnail"
doc = @session.get_object(id, context)

renditions = doc.renditions

puts "Renditions"
renditions.each do |r|
  puts "Kind" + r.kind
  puts "Mimetype: " + r.mime_type
end
```

Note: If you run the code above you might not get the renditions directly. Many repositories renders them asynchronously so it will take some time before you see them.

## Multi-filing
Multi-filing allows you to file a document object in more than one folder. This capability are optional, and your repository may not support them.

```ruby
doc = @session.root_folder.create_text_doc("Multi-filing.txt", "Content")
folder = @session.root_folder.create_cmis_folder("multi-filing")
puts "Document parent count: " + doc.parents.size.to_s
doc.add_to_folder(folder, true) # true means all versions
puts "Document parent count: " + doc.parents.size.to_s
```

## Access control

Document or folder objects can have an access control list (ACL), which controls access to the object. An ACL is a list of Access Control Entries (ACEs). An ACE grants one or more permissions to a principal. A principal is a user, group, role, or something similar.

An ACE contains:
* One String with the principalid
* One or more Strings with the names of the permissions.
* A boolean flag direct, which is true if the ACE is directly assigned to the object, or false if the ACE is somehow derived

There are three basic permissions predefined by CMIS:
* cmis:read: permission for reading properties and reading content
* cmis:write: permission to write properties and the content of an object. A respository can defin the property to include cmis:read
* cmis:all: all the permissions of a repository. It includes all other basic CMIS permissions.

How these basic permissions are mapped to allowable actions is repository specific. You can discover the repository semantics for basic permissions with regard to allowable actions by examining the mappings parameter returned by session method repository_info. A repository can extend the basic permissions with its own repository-specific permissions. The folowing code snippet prints out the permissions available for a repository, 
and the mappings of allowable actions to repository permissions:

```ruby
acl_caps = @session.repository_info.acl_capabilities

puts "Propogation for this repository is " + acl_caps.acl_propagation.to_s

puts "Permissions for this repository are: "
acl_caps.permissions.each do |p|
  puts "ID: " + p.id + " description: " + p.description 
end

puts "Permission mappings for this repository are:"
repo_mapping = acl_caps.permission_mapping

repo_mapping.each do |key, value|
  puts key + " maps to " + repo_mapping.get(key).permissions.to_s
end
```

You can specify how a repository should handle non-direct ACEs when you create an ACL, by specifying one of the following acl propogation values:

* OBJECTONLY: apply ACEs to a document or folder, without changing the ACLs of other objects
* PROPAGATE: apply ACEs to the given object and all inheriting objects
* REPOSITORYDETERMINED: allow the repository to use its own method of computing how changing an ACL for an object influences the non-direct ACEs of other objects.

The following example creates a folder object, and prints out the ACEs in the created folder's ACL. It then creates a new ACL with one ACE, adds it to the folder, retrieves the folder again, and prints out the ACEs now present in the folder's ACL:

```ruby
folder = @session.root_folder.create_cmis_folder("ACL test")
oc = CMIS::OperationContextImpl.new
oc.include_acls = true 
folder = @session.get_object(folder, oc)

aces = folder.acl.aces
puts "Permissions before we add the guest user:"
aces.each do |a|
  puts "Principal: " + a.principal.id
  a.permissions.each do |p|
    puts "Permission ID: " + p
  end
end

permissions = ["cmis:read"]
principal = "guest" # Built in user in Alfresco
ace_in = @session.object_factory.create_ace(principal, permissions)
folder.add_acl([ace_in], CMIS::AclPropagation::REPOSITORYDETERMINED)
folder = @session.get_object(folder, oc)

aces = aces = folder.acl.aces
puts "Permissions after we added the guest user:"
aces.each do |a|
  puts "Principal: " + a.principal.id
  a.permissions.each do |p|
    puts "Permission ID: " + p
  end
end
```

## Relationships

A Relationship object is a relationship between a source object and a target object. The relationship has direction, from source to target. It is non-invasive, in that a relationship does not modify either the source or the target object. A relationship object has a type, like any other CMIS object. The source and target objects must be independent objects, such as a document, folder, or policy objects. A relationship object does not have a content-stream, and is not versionable, queryable, or fileable.

A repository does not have to support relationships. If it doesn't the relationship base object-type will not be returned by a "get types" call.

The following example creates a relationship between 2 objects. Alfresco supports relationships, but the base type cmis:relationship is not defined as creatable, so the example uses an existing type R:cmiscustom:assoc which is a creatable sub-type of cmis:relationship in Alfresco:

```ruby
content_stream = CMIS::create_content_stream("/Users/ricn/source.txt", @session)
source_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "D:cmiscustom:document", CMIS::PropertyIds::NAME => "source.txt" }
source_doc = @session.root_folder.create_document(source_props, content_stream, CMIS::VersioningState::MAJOR)

content_stream = CMIS::create_content_stream("/Users/ricn/target.txt", @session)
target_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "D:cmiscustom:document", CMIS::PropertyIds::NAME => "target.txt" }
target_doc = @session.root_folder.create_document(target_props, content_stream, CMIS::VersioningState::MAJOR)
        
rel_props = {
  "cmis:sourceId" => source_doc.id, 
  "cmis:targetId" => target_doc.id, 
  "cmis:objectTypeId" => "R:cmiscustom:assoc"
}

rel = @session.create_relationship(rel_props)
rel = @session.get_object(rel)

puts rel.source.id
puts rel.target.id
```

## Exceptions
If something goes wrong in an OpenCMIS method, an exception will be thrown. All OpenCMIS exceptions extend [CmisBaseException](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/commons/exceptions/package-tree.html) which is a Java runtime exception. Because all exceptions are runtime, you do not have to catch or specify the exceptions in your own code.

When you are using the ATOMPUB binding, [CmisBaseException](http://chemistry.apache.org/java/0.8.0/maven/apidocs/org/apache/chemistry/opencmis/commons/exceptions/package-tree.html) provides a error_content method which returns the content of the error page returned from the server, if there is one. This can be very useful debugging, as the server side is normally able to provide far more information that the client. 
In the following example, a CMISInvalidArgumentException exception is forced by trying to create a folder with an invalid type. The rescue block prints the server's error page:

```ruby
begin
  folder_props = { CMIS::PropertyIds::OBJECT_TYPE_ID => "INVALIDOBJECTTYPEID", CMIS::PropertyIds::NAME => "folder name" }
  folder = @session.root_folder.create_folder(folder_props)
rescue StandardError => e
  puts e.message
  puts e.error_content
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
