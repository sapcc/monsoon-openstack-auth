require 'spec_helper'

describe MonsoonOpenstackAuth::Session do
  before(:each) do
    request = double('request')
    request.stub(:session_options){ {id:nil} }
    request.stub(:headers){ {} }
    
    @controller = double('controller')
    @controller.stub(:session){ Hash.new }
    @controller.stub(:request){ request }
  end
  
  describe "initialize" do
    it "should create a new session object" do
      session = MonsoonOpenstackAuth::Session.new(@controller, 'europe')
      expect(session).not_to be(nil)
    end
  end
  
  # context "session id is presented and session is available and sesion token is valid" do
  #   before :each do
  #     @controller.request.stub(:session_options){ {id: '12345'} }
  #
  #     @controller.stub(:session){ {monsoon_openstack_auth_token: ApiStub.keystone_token.merge("expires_at"=>Time.now+1.hour)} }
  #
  #
  #   end
  #
  #   describe "authenticate_or_redirect" do
  #     it "should authenticate from session" do
  #       session = MonsoonOpenstackAuth::Session.new(@controller, 'europe')
  #       session.authenticate_or_redirect
  #     end
  #   end
  # end
end
