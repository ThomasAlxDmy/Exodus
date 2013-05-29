# -*- encoding: utf-8 -*-
require File.expand_path('../lib/exodus/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Thomas Dmytryk']
  gem.email         = ['thomas@fanhattan.com', 'thomas.dmytryk@supinfo.com']
  gem.description   = %q{Exodus is a migration framework for MongoDb}
  gem.summary       = %q{Exodus uses mongomapper to provide a complete migration framework}
  gem.homepage      = 'https://github.com/ThomasAlxDmy/Exodus'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'exodus'
  gem.require_paths = ['lib']
  gem.version       = Exodus::VERSION

  gem.add_dependency 'mongo_mapper'
  gem.add_dependency 'bson_ext'
  
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rake'
end
