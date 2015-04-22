require 'spec_helper'

describe MonsoonOpenstackAuth::ComputeService do
  before :each do 
    @driver = double("driver")
    Fog::Compute::OpenStack.stub(new: @driver)
    @current_user = double("current_user")
    @current_user.stub(id: 1, token: '1234556')
    @service = MonsoonOpenstackAuth::ComputeService.new("europe", @current_user)   
  end
  
  context "undefined method" do
    it "should delegate method to driver" do
      expect(@driver).to receive(:domains)
      @service.domains
    end
  end
end