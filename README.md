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

## Usage

This guide is for JRuby developers who want to access CMIS-compliant content repositories from JRuby. The examples has been tested with Alfresco Community Edition 4.2.c which is one of the most feature complete CMIS content repository.

If you want to run the code snippets below you can download and install Alfresco. You can find the version that fits your platform here: http://wiki.alfresco.com/wiki/Download_and_Install_Alfresco

You can also run the examples using the Public Alfresco CMIS server. More information can be found here: http://cmis.alfresco.com. The atom url for the public 
server is http://cmis.alfresco.com/cmisatom.

Nuxeo also provides a demo server. More information can be found here: http://doc.nuxeo.com/display/NXDOC/CMIS+for+Nuxeo#CMISforNuxeo-Onlinedemo .

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
```

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
```

#### Download a document to your local disk

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
query = "SELECT * FROM cmis:document WHERE cmis:name LIKE 'cmis%'"
q = @session.query(query, false) # false means only latest versions

q.each do |result|
  puts result.property_value_by_query_name("cmis:name")
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

The following code example checks if this repository supports renditions. It then scans the object tree starting from the root folder for a document object that has renditions associated with it. It then gets the document again using an OperationContext to retrieve all renditions of a particular type.

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



## DOCUMENTION TODO:
* Add Multi-filing and Unfiling examples
* Add Relationships examples
* Add Access control examples
* Add OperationContext examples
* Add Advanced types usage examples
* Add Performance notes
* Add Troubleshooting notes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
