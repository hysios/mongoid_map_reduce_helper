# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid_map_reduce_helper/version'

Gem::Specification.new do |gem|
  gem.name          = "mongoid_map_reduce_helper"
  gem.version       = MongoidMapReduceHelper::VERSION
  gem.authors       = ["hysios hu"]
  gem.email         = ["hysios@gmail.com"]
  gem.description   = %q{An easy way to using map reduce}
  gem.summary       = %q{q mongoid map reduce helper util}
  gem.homepage      = "http://github.com/hysios/mongoid_map_reduce_helper.git"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'mongoid', '>= 3.0.0'
  gem.add_dependency 'activesupport'

end
