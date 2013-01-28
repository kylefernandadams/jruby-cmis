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
puts "Trying to connect to repository with id #{available_repos[0].id}"
@session = CMIS::create_session(atom_url, user, password, available_repos[0].id)

```

## Working with folders and documents

### Finding the contents of the root folder

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

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
