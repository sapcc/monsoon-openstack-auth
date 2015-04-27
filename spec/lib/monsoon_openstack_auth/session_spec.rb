require 'spec_helper'

describe MonsoonOpenstackAuth::Session do
  test_token = HashWithIndifferentAccess.new(ApiStub.keystone_token.merge("expires_at" => (Time.now+1.hour).to_s))

  before :each do    
    Fog::IdentityV3::OpenStack.stub(:new)

    MonsoonOpenstackAuth.configure do |config|
      # connection driver, default MonsoonOpenstackAuth::Driver::Default (Fog)
      # config.connection_driver = DriverClass
      config.connection_driver.api_endpoint = "http://localhost:8183/v3/auth/tokens"
      config.connection_driver.api_userid   = "u-admin"
      config.connection_driver.api_password = "secret"
    end

    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:validate_token).with(test_token[:value]) { test_token } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:validate_token).with("INVALID_TOKEN") { raise Fog::Identity::OpenStack::NotFound.new } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_credentials).with("test","secret").and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_credentials).with("me","me") { raise Fog::Identity::OpenStack::NotFound.new } 
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_token).and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_external_user).and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_access_key).with("good_key").and_return(test_token)
    MonsoonOpenstackAuth::ApiClient.any_instance.stub(:authenticate_with_access_key).with("bad_key").and_return(nil)
  end
  
  context "included in controller", :type => :controller do
    before do
      controller.main_app.stub(:root_path).and_return('/')  
      controller.monsoon_openstack_auth.stub(:new_session_path).and_return('/auth/sessions/new')
    end
    
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {c.params[:organization_id]}, project_id: -> c {c.params[:project_id]}
  
      def index
        head :ok
      end
    end
  
    context "missing region id" do

      it "should throw an error" do
        controller.stub(:params) { {} }
        expect { get "index", region_id: 'europe' }.to raise_error(MonsoonOpenstackAuth::InvalidRegion)
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
        expect(controller.services.identity.is_a? MonsoonOpenstackAuth::IdentityService).to eq(true)
      end
      
      it "should return identity service" do
        expect(controller.services.compute.is_a? MonsoonOpenstackAuth::ComputeService).to eq(true)
      end
      
      it "should return identity service" do
        expect(controller.services.volume.is_a? MonsoonOpenstackAuth::VolumeService).to eq(true)
      end
    end
    
    context "token auth is allowed" do

      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ true  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ false }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { false }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { false }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { false }
      end
    
      context "no auth token presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end  
    
      context "invalid auth token" do
        it "should redirect to main app's root path" do
          request.headers["X-Auth-Token"]="INVALID_TOKEN"
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end
    
      context "session token not presented" do
        it "should authenticate user from auth token" do
          request.headers["X-Auth-Token"]=test_token[:value]
          get "index", { region_id: 'europe' }
          expect(controller.current_user).not_to be(nil)
          expect(controller.current_user.token).to eq(test_token[:value])
        end
      end
    
      context "session token presented" do
        before do
          @session_store = MonsoonOpenstackAuth::SessionStore.new(controller.session)
          @session_store.token=test_token
        end

        it "should authenticate user from session token" do
          request.headers["X-Auth-Token"]=test_token[:value]
          get "index", { region_id: 'europe' }
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        end
      end
    end
  
    context "basic auth is allowed" do
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ false  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ true }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { false }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { false }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { false }
      end

      context "no basic auth presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "wrong basic auth credentials" do
        it "should redirect to main app's root path" do
          request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("me","me")
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid basic auth presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).and_return({})
          request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
          get "index", region_id: 'europe'
          expect(controller.current_user).not_to be(nil)
        end
      end
    end

    context "sso auth is allowed" do
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ false  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ false }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { true }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { false }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { false }
      end

      context "no sso header presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid sso header presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return({})
          request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
          request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

          get "index", region_id: 'europe'
          expect(controller.current_user).not_to be(nil)
        end
      end
    end

    context "acccess_key auth is allowed" do
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ false  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ false }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { false }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { true }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { false }
      end

      context "no access key param presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid access key  presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return({})

          get "index", region_id: 'europe',access_key:'good_key'
          expect(controller.current_user).not_to be(nil)
        end
      end

      context "valid rails_auth_token  presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return({})

          get "index", region_id: 'europe',access_key:'good_key'
          expect(controller.current_user).not_to be(nil)
        end
      end

      context "invalid access key param presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe',access_key:'bad_key'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "invalid rails_auth_token  param presented" do
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe',access_key:'bad_key'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end


    end

    context "form auth is allowed" do
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ false  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ false }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { false }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { true }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { false }
      end

      context "session token not presented" do
        it "should authenticate user from auth token" do
          get "index", { region_id: 'europe' }
          expect(response).to redirect_to(controller.monsoon_openstack_auth.new_session_path('europe'))
        end
      end

      context "session token presented" do
        before do
          @session_store = MonsoonOpenstackAuth::SessionStore.new(controller.session)
          @session_store.token=test_token
        end

        it "should authenticate user from session token" do
          get "index", { region_id: 'europe' }
          expect(controller.current_user).not_to be(nil)
          expect(controller.current_user.token).to eq(test_token[:value])
        end
      end
    end

    context "all auth methods are allowed" do
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ true  }
        MonsoonOpenstackAuth.configuration.stub(:basic_auth_allowed?){ true }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { true }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { true }
        MonsoonOpenstackAuth.configuration.stub(:access_key_auth_allowed?)  { true }
      end


      it "authenticates from session" do
        @session_store = MonsoonOpenstackAuth::SessionStore.new(controller.session)
        @session_store.token=test_token

        request.headers["X-Auth-Token"]=test_token[:value]
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_external_user)

        get "index", { region_id: 'europe' }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
      end

      it "authenticates from auth token" do
        request.headers["X-Auth-Token"]=test_token[:value]
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:validate_token).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_external_user)

        get "index", { region_id: 'europe' }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client('europe')).to have_received(:validate_token)
      end

      it "authenticates from sso" do
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)

        get "index", { region_id: 'europe' }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client('europe')).to have_received(:authenticate_external_user)
      end

      it "authenticates from access_key" do
        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_external_user)

        get "index", { region_id: 'europe',access_key:"good_key" }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client('europe')).to have_received(:authenticate_with_access_key)
      end

    end
  end
end
