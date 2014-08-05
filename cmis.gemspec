# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cmis/version'

Gem::Specification.new do |gem|
  gem.name          = "jruby-cmis"
  gem.version       = CMIS::VERSION
  gem.authors       = ["Kyle Adams"]
  gem.email         = ["kyle.adams@alfresco.com"]
  gem.description   = %q{A thin JRuby wrapper for the Apache Chemistry OpenCMIS client.}
  gem.summary       = %q{A thin JRuby wrapper for the Apache Chemistry OpenCMIS client.}
  gem.homepage      = "https://github.com/kylefernandadams/jruby-cmis"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_development_dependency "rspec"
  gem.platform = "java"
end
