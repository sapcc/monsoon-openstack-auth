require 'spec_helper'

describe MonsoonOpenstackAuth::Authentication::AuthSession do
  test_token = HashWithIndifferentAccess.new(ApiStub.keystone_token.merge("expires_at" => (Time.now+1.hour).to_s))
  test_token_domain = test_token.fetch("domain",{}).fetch("id",nil)
  test_token_project = test_token.fetch("project",{}).fetch("id",nil)

  before :each do    
    MonsoonOpenstackAuth.configure do |config|
      config.connection_driver.api_endpoint = "http://localhost:5000/v3/auth/tokens"
    end

    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:validate_token).with(test_token[:value]).and_return(test_token) 
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:validate_token).with("INVALID_TOKEN").and_return(nil)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("test","secret").and_return(test_token)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("me","me").and_return(nil)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("test","test",anything).and_return(test_token)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_token).with(anything,anything).and_return(test_token)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return(test_token)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).with("good_key").and_return(test_token)
    allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).with("bad_key").and_return(nil)
  end
  
  context "included in controller", :type => :controller do
    before do
      controller.main_app.stub(:root_path).and_return('/')  
      controller.monsoon_openstack_auth.stub(:new_session_path).and_return('/auth/sessions/new')
      controller.monsoon_openstack_auth.stub(:login_path).and_return('/auth/sessions/new')
    end
    
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, domain: -> c {c.params[:domain]}, project: -> c {c.params[:project]}
  
      def index
        head :ok
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
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end  
    
      context "invalid auth token" do
        it "should redirect to main app's root path" do
          request.headers["X-Auth-Token"]="INVALID_TOKEN"
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end
    
      context "session token not presented" do
        it "should authenticate user from auth token" do
          request.headers["X-Auth-Token"]=test_token[:value]
          get "index"
          expect(controller.current_user).not_to be(nil)
          expect(controller.current_user.token).to eq(test_token[:value])
        end
      end
    
      context "session token presented" do
        before do
          @session_store = MonsoonOpenstackAuth::Authentication::SessionStore.new(controller.session)
          @session_store.token=test_token
        end

        it "should authenticate user from session token" do
          request.headers["X-Auth-Token"]=test_token[:value]
          get "index"
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
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "wrong basic auth credentials" do
        it "should redirect to main app's root path" do
          request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("me","me")
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid basic auth presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).and_return({})
          request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
          get "index"
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
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid sso header presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return({})
          request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
          request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

          get "index"
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
          get "index"
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "valid access key  presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return({})

          get "index",access_key:'good_key'
          expect(controller.current_user).not_to be(nil)
        end
      end

      context "valid rails_auth_token  presented" do
        it "should authenticate user" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return({})

          get "index", rails_auth_token: 'good_key'
          expect(controller.current_user).not_to be(nil)
        end
      end

      context "invalid access key param presented" do
        it "should redirect to main app's root path" do
          get "index",access_key:'bad_key'
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
      end

      context "invalid rails_auth_token  param presented" do
        it "should redirect to main app's root path" do
          get "index", rails_auth_token: 'bad_key'
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
          get "index"
          expect(response).to redirect_to(controller.monsoon_openstack_auth.login_path)
        end
        
        it "should authenticate user from auth token by given domain_id" do
          get "index", { region_id: 'europe', domain: 'default' }
          expect(response).to redirect_to(controller.monsoon_openstack_auth.login_path('default'))
        end
      end

      context "session token presented" do
        before do
          @session_store = MonsoonOpenstackAuth::Authentication::SessionStore.new(controller.session)
          @session_store.token=test_token
        end

        it "should authenticate user from session token" do
          get "index"
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
        @session_store = MonsoonOpenstackAuth::Authentication::SessionStore.new(controller.session)
        @session_store.token=test_token

        request.headers["X-Auth-Token"]=test_token[:value]
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "CN=test"

        #allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:get_rescoped_token).and_return(true)
        
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_external_user)

        get "index", { domain: test_token_domain, project: test_token_project }
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

        get "index", { domain: test_token_domain, project: test_token_project }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client).to have_received(:validate_token)
      end

      it "authenticates from sso" do
        MonsoonOpenstackAuth.configuration.provide_sso_domain=true
        domain = double("domain")
        domain.stub(:id).and_return('o-sap_default')
        
        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:domain_by_name).with('sap_default').and_return(domain)
        
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "/O=SAP-AG/CN=test"

        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)

        get "index", { domain: test_token_domain, project: test_token_project }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client).to have_received(:authenticate_external_user).with("test",{domain_name: 'sap_default'})
      end
      
      it "authenticate from sso ignoring domain" do
        MonsoonOpenstackAuth.configuration.provide_sso_domain=false
        
        domain = double("domain")
        domain.stub(:id).and_return('o-sap_default')
        
        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:domain_by_name).with('sap_default').and_return(domain)
        
        request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials("test","secret")
        request.env['HTTP_SSL_CLIENT_VERIFY'] = 'SUCCESS'
        request.env['HTTP_SSL_CLIENT_S_DN'] = "/O=SAP-AG/CN=test"

        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_external_user).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)

        get "index", { domain: test_token_domain, project: test_token_project }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        
        expect(MonsoonOpenstackAuth.api_client).to have_received(:authenticate_external_user).with("test",nil)
      end

      it "authenticates from access_key" do
        allow_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_access_key).and_return(test_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:validate_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_token)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_with_credentials)
        expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).not_to receive(:authenticate_external_user)

        get "index", { access_key:"good_key", domain: test_token_domain, project: test_token_project  }
        expect(controller.current_user).not_to be(nil)
        expect(controller.current_user.token).to eq(test_token[:value])
        expect(MonsoonOpenstackAuth.api_client).to have_received(:authenticate_with_access_key)
      end

    end
    
    describe "::create_from_login_form" do
      context "domain_name is nil" do
        it "should call authenticate using id and password" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("test","test",nil)
          MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(controller,'test','test')  
        end
      end
      context "domain_id is not nil" do
        it "should call authenticate using id and password" do
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("test","test", domain: 'test_domain')
          MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(controller,'test','test','test_domain',nil)  
        end
      end      
      context "domain_name is not nil" do
        it "should call authenticate using id and password" do
          #allow(@driver).to receive(:authenticate).with({ auth: { identity: { methods: ["password"], password:{user: {name: 'test', password: 'test', domain: {id: 'test_domain'} } } } } })
          expect_any_instance_of(MonsoonOpenstackAuth::ApiClient).to receive(:authenticate_with_credentials).with("test","test", domain_name: 'test_domain')
          MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(controller,'test','test',nil,'test_domain')  
        end
      end
    end
    
    describe '::check_authentication' do
      
      context "not authenticated" do
        it "raise not_authorized_error if not authenticated" do
          allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(false)
        
          expect {
            MonsoonOpenstackAuth::Authentication::AuthSession.check_authentication(controller, {domain:'aaa',project:'bbb',raise_error:true})
          }.to raise_error
        end
        
        it "redirect if not authenticated" do
          allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(false)
          expect_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:redirect_to_login_form).and_return(true)
          
          MonsoonOpenstackAuth::Authentication::AuthSession.check_authentication(controller, {domain:'aaa',project:'bbb'})
        end
      end

    end
  end
end
