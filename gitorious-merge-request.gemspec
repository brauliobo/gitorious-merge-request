# -*- encoding: utf-8 -*-

require File.expand_path('./lib/gitorious-merge-request/version', File.dirname(__FILE__))

Gem::Specification.new do |gem|
  gem.authors       = ["Braulio Bhavamitra"]
  gem.email         = ["brauliobo@gmail.com"]
  gem.summary       = "Manage Gitorious' merge requests (create, remove, show, ...)"
  gem.description   = gem.summary
  gem.homepage      = "http://github.com/brauliobo/gitorious-merge-request"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "gitorious-merge-request"
  gem.require_paths = ["lib"]
  gem.version       = GitoriousMergeRequest::Version

  gem.add_dependency 'activesupport'
  gem.add_dependency 'trollop'
  gem.add_dependency 'mechanize'
  gem.add_dependency 'highline'

end
