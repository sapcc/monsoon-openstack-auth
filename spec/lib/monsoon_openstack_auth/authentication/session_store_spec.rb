require 'spec_helper'

describe MonsoonOpenstackAuth::Authentication::SessionStore do
  
  describe 'initialize' do
    it "should create a new session_store object" do 
      expect(MonsoonOpenstackAuth::Authentication::SessionStore.new({})).not_to be(nil)
    end
  end
  
  describe "session store object" do    
    describe "token_presented?" do
      context "token is presented" do
        let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ monsoon_openstack_auth_token: ApiStub.keystone_token.merge(expires_at:(Time.now+1.day).to_s )}) }
      
        it "should return true" do  
          expect(session.token_presented?).to eq(true)
        end
      end
      
      context "session is empty" do
        let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ }) }
        it "should return false" do
          expect(session.token_presented?).to eq(false)
        end
      end
    end
  
    describe "token_valid?" do
      context "token is presented and valid" do
        let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ monsoon_openstack_auth_token: ApiStub.keystone_token.merge(expires_at:(Time.now+1.day).to_s )}) }
      
        it "should return true" do
          expect(session.token_valid?).to eq(true)
        end
      end
      
      context "token is not presented" do
        let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ }) }
        it "should return false" do
          expect(session.token_valid?).to eq(false)
        end
      end
      
      context "token is presented but invalid" do
        let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ monsoon_openstack_auth_token: ApiStub.keystone_token.merge(expires_at:(Time.now-1.day).to_s ) }) }
        it "should return false" do
          expect(session.token_valid?).to eq(false)
        end
      end
    end
    
    describe "token_eql?" do
      let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ monsoon_openstack_auth_token: ApiStub.keystone_token.merge(value:ApiStub.keystone_token["value"])}) }
      
      it "should return true" do
        expect(session.token_eql?(ApiStub.keystone_token["value"])).to eq(true)
      end
      
      it "should return false" do
        expect(session.token_eql?(ApiStub.authority_token["value"])).to eq(false)
      end
    end

    describe "token" do
      let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({ monsoon_openstack_auth_token: ApiStub.keystone_token}) }
      it "should return the token" do
        expect(session.token).to eq(ApiStub.keystone_token)
      end
    end

    describe "token=" do
      let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({})}
      it "should set token" do
        session.token=ApiStub.keystone_token
        expect(session.token).to eq(ApiStub.keystone_token)
      end
    end

    describe "delete_token" do
      let(:session) { MonsoonOpenstackAuth::Authentication::SessionStore.new({monsoon_openstack_auth_token: ApiStub.keystone_token})}
      it "should delete token" do
        expect(session.token).to eq(ApiStub.keystone_token)
        session.delete_token
        expect(session.token).to eq(nil)
      end
    end
  end
end
