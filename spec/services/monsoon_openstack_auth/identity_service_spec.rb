require 'spec_helper'

describe MonsoonOpenstackAuth::IdentityService do
  before :each do 
    @driver = double("driver")
    Fog::IdentityV3::OpenStack.stub(new: @driver)
    @current_user = double("current_user")
    @current_user.stub(id: 1, token: '1234556')
    @service = MonsoonOpenstackAuth::IdentityService.new("europe", @current_user)   
  end
  
  context "undefined method" do
    it "should delegate method to driver" do
      expect(@driver).to receive(:domains)
      @service.domains
    end
  end
  
  it "should respond to user_domains" do 
    expect(@service.respond_to? :user_domains).to eq(true)
  end
  
  it "should respond to domain" do 
    expect(@service.respond_to? :domain).to eq(true)
  end
  
  it "should respond to domain_projects" do 
    expect(@service.respond_to? :domain_projects).to eq(true)
  end
  
  it "should respond to project" do 
    expect(@service.respond_to? :project).to eq(true)
  end
  
  describe "user_domains" do
    #TODO
  end
  
  describe "domain" do
    #TODO
  end
  
  describe "domain_projects" do
    #TODO
  end
  
  describe "project" do
    #TODO
  end

end