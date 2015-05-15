require File.join(Gem.loaded_specs['monsoon-openstack-auth'].full_gem_path,'spec/support/api_stub')

module AuthenticationStub
  
  def self.included(base)
    base.send :include, ClassMethods
  end
  
  def self.bad_domain_id
    'BAD_DOMAIN'
  end
  
  def self.test_token 
    @test_token ||= HashWithIndifferentAccess.new(ApiStub.keystone_token.merge("expires_at" => (Time.now+1.hour).to_s))
  end
  
  def self.domain_id
    @domain_id ||= (test_token.fetch("domain",{}).fetch("id",nil) || test_token.fetch("project",{}).fetch("domain",{}).fetch("id",nil))
  end
  
  def self.project_id
    @project_id ||= test_token.fetch("project",{}).fetch("id",nil)
  end
  
  def self.default_domain_id
    domain_id
  end
  
  module ClassMethods
    
    def stub_auth_configuration
      allow(Fog::IdentityV3::OpenStack).to receive(:new)
      default_domain = double('default domain')
      allow(default_domain).to receive(:id).and_return(AuthenticationStub.default_domain_id)
      allow(MonsoonOpenstackAuth).to receive(:default_domain).and_return(default_domain)
      allow(MonsoonOpenstackAuth).to receive(:default_region).and_return('europe')
    end

  
    def stub_authentication
      stub_auth_configuration
      
      allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_token).
        with(AuthenticationStub.test_token["value"], domain: {id: AuthenticationStub.domain_id})
        .and_return(AuthenticationStub.test_token)
      
      allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_token).
        with(AuthenticationStub.test_token["value"], domain: {id: AuthenticationStub.bad_domain_id})
        .and_raise{StandardError.new}
          
      @session_store = MonsoonOpenstackAuth::Authentication::SessionStore.new(controller.session)
      @session_store.token=AuthenticationStub.test_token
    end
  end
end