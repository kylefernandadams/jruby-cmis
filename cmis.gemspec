# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cmis/version'

Gem::Specification.new do |gem|
  gem.name          = "cmis"
  gem.version       = Cmis::VERSION
  gem.authors       = ["Richard Nyström"]
  gem.email         = ["ricny046@gmail.com"]
  gem.description   = %q{A thin JRuby wrapper for the Apache Chemistry OpenCMIS client.}
  gem.summary       = %q{A thin JRuby wrapper for the Apache Chemistry OpenCMIS client.}
  gem.homepage      = "https://github.com/ricn/cmis"
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.add_dependency "activemodel"
  gem.add_development_dependency "rspec"
  gem.platform = "java"
end
