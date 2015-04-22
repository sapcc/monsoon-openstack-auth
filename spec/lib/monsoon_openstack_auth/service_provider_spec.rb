require 'spec_helper'

describe MonsoonOpenstackAuth::ServiceProvider do
  before :each do
    Fog::Compute::OpenStack.stub(:new)
    Fog::Volume::OpenStack.stub(:new)
    Fog::IdentityV3::OpenStack.stub(:new)
    
    @current_user = double("user")
    @current_user.stub(token: '123456789')
    @service_provider = MonsoonOpenstackAuth::ServiceProvider.new("europe", @current_user)  
  end
  
  it "should return default identity service" do
    expect(@service_provider.identity.is_a? MonsoonOpenstackAuth::IdentityService).to eq(true)
  end
  
  it "should return default compute service" do
    expect(@service_provider.compute.is_a? MonsoonOpenstackAuth::ComputeService).to eq(true)
  end
  
  it "should return default volume service" do
    expect(@service_provider.volume.is_a? MonsoonOpenstackAuth::VolumeService).to eq(true)
  end
  
  context "add new service" do
    class MonsoonOpenstackAuth::MyNewService < MonsoonOpenstackAuth::OpenstackServiceProvider::Base
    end
    
    it "should provide my new service" do
      expect(@service_provider.my_new.is_a? MonsoonOpenstackAuth::MyNewService).to eq(true)
    end
  end
  
  context "service does not extend MonsoonOpenstackAuth::OpenstackServiceProvider::Base" do
    class MonsoonOpenstackAuth::TestService 
    end
    
    it "should not provide the test service" do
      expect{
        @service_provider.test
      }.to raise_error
    end
  end

end
