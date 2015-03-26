$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "monsoon_identity/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "monsoon_identity"
  s.version     = MonsoonIdentity::VERSION
  s.authors     = ["Andreas Pfau"]
  s.email       = ["andreas.pfau@sap.com"]
  s.homepage    = "https://github.com/sapcc/monsoon/monsoon-identity"
  s.summary     = "Summary of MonsoonIdentity."
  s.description = "Description of MonsoonIdentity."
  #s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails"
  s.add_dependency 'monsoon-fog'
  
  s.add_development_dependency "sqlite3"
end

