# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "egregious/version"

Gem::Specification.new do |s|
  s.name        = "egregious"
  s.version     = Egregious::VERSION
  s.authors     = ["Russell Edens"]
  s.email       = ["rx@voomify.com"]
  s.homepage    = "http://github.com/voomify/egregious"
  s.summary     = %q{Egregious is a rails based exception handling gem for well defined http exception handling for json, xml and html. Requires Rails.}
  s.description = %q{Egregious is a rails based exception handling gem for well defined http exception handling for json, xml and html. Requires Rails.}
  s.license = 'MIT'
  s.rubyforge_project = "egregious"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]


  s.add_runtime_dependency "rails", '> 4.0', '< 6'
  s.add_runtime_dependency "rack", '>= 1.2.5'
  s.add_runtime_dependency "htmlentities"

  # specify any dependencies here; for example:
  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "json"
  s.add_development_dependency "hpricot"
  s.add_development_dependency "warden"
  s.add_development_dependency "cancan"
  s.add_development_dependency "mongoid"
  s.add_development_dependency "appraisal"

end
