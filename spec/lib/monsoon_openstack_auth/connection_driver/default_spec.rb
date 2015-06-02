require 'spec_helper'

describe MonsoonOpenstackAuth::ConnectionDriver::Default do
  before :each do
    @fog_driver = double("fog driver").as_null_object
    @fog_driver.stub(:tokens).and_return(double('tokens').as_null_object)
    
    Fog::IdentityV3::OpenStack.stub(:new).and_return(@fog_driver)
    @driver = MonsoonOpenstackAuth::ConnectionDriver::Default.new("europe")

  end
  
  describe "authenticate_external_user" do
    context "scope is nil" do
      it "should call authenitcate without scope" do
        allow(@fog_driver.tokens).to receive(:authenticate).and_return(double("token attributes").as_null_object)
        @driver.authenticate_external_user("test")
        expect(@fog_driver.tokens).to have_received(:authenticate).with({ auth: { identity: {methods: ["external"], external:{user: "test" } }}}   )
      end
    end
    
    context "scope is not nil" do
      it "should call authenitcate with scope" do
        allow(@fog_driver.tokens).to receive(:authenticate).and_return(double("token attributes").as_null_object)
        @driver.authenticate_external_user("test", domain: 'o-sap_default')
        expect(@fog_driver.tokens).to have_received(:authenticate).with({ auth: { identity: {methods: ["external"], external:{user: "test", domain: {id: 'o-sap_default'} } }}}   )
      end
    end
  end
  
end