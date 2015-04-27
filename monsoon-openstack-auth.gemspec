$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "monsoon_openstack_auth/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "monsoon-openstack-auth"
  s.version     = MonsoonOpenstackAuth::VERSION
  s.authors     = ["Andreas Pfau"]
  s.email       = ["andreas.pfau@sap.com"]
  s.homepage    = "https://github.com/sapcc/monsoon/monsoon-identity"
  s.summary     = "Summary of MonsoonOpenstackAuth."
  s.description = "Description of MonsoonOpenstackAuth."
  #s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'rails'
  s.add_dependency 'hashie'
  s.add_dependency 'uglifier', '>= 1.3.0'

end

