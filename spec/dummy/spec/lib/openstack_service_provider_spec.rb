require 'spec_helper'

describe OpenstackServiceProvider::ServicesManager do
  before :each do
    Fog::Compute::OpenStack.stub(:new)
    Fog::Volume::OpenStack.stub(:new)
    Fog::IdentityV3::OpenStack.stub(:new)
    
    @current_user = double("user")
    @current_user.stub(token: '123456789')
    @service_provider = OpenstackServiceProvider::ServicesManager.new("http://localhost","europe", @current_user)  
  end
  
  it "should return default identity service" do
    expect(@service_provider.identity.is_a? Openstack::IdentityService).to eq(true)
  end
  
  it "should return default compute service" do
    expect(@service_provider.compute.is_a? Openstack::ComputeService).to eq(true)
  end
  
  it "should return default volume service" do
    expect(@service_provider.volume.is_a? Openstack::VolumeService).to eq(true)
  end
  
  context "add new service" do
    class Openstack::MyNewService < OpenstackServiceProvider::BaseProvider
    end
    
    it "should provide my new service" do
      expect(@service_provider.my_new.is_a? Openstack::MyNewService).to eq(true)
    end
  end
  
  context "service does not extend OpenstackService::BaseProvider" do
    class Openstack::TestService 
    end
    
    it "should not provide the test service" do
      expect{
        @service_provider.test
      }.to raise_error
    end
  end

end

describe OpenstackServiceProvider::Services, type: :controller do
  test_token = HashWithIndifferentAccess.new(ApiStub.keystone_token.merge("expires_at" => (Time.now+1.hour).to_s))
  
  before :each do    
    Fog::IdentityV3::OpenStack.stub(:new)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:validate_token).with(test_token[:value]) { test_token } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:validate_token).with("INVALID_TOKEN") { raise Fog::Identity::OpenStack::NotFound.new } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_credentials).with("test","secret").and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_credentials).with("me","me") { raise Fog::Identity::OpenStack::NotFound.new } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_token).and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_external_user).and_return(test_token)
  end
  
  controller do # anonymous subclass of ActionController::Base
    authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {c.params[:organization_id]}, project_id: -> c {c.params[:project_id]}
    include OpenstackServiceProvider::Services
    
    def index
      head :ok
    end
  end
  
  context "get services" do
    before :each do
      Fog::Compute::OpenStack.stub(:new)
      Fog::Volume::OpenStack.stub(:new)
      Fog::IdentityV3::OpenStack.stub(:new)
      
      request.headers["X-Auth-Token"]=test_token[:value]
      get "index", { region_id: 'europe' }
    end
    
    it "should respond to services method" do
      expect(controller.respond_to? :services).to eq(true)
    end
      
    it "should return identity service" do
      expect(controller.services.identity.is_a? Openstack::IdentityService).to eq(true)
    end
    
    it "should return identity service" do
      expect(controller.services.compute.is_a? Openstack::ComputeService).to eq(true)
    end
    
    it "should return identity service" do
      expect(controller.services.volume.is_a? Openstack::VolumeService).to eq(true)
    end
  end
end
