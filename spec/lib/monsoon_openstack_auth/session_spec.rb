require 'spec_helper'

describe MonsoonOpenstackAuth::Session do
  
  context "included by a controller", :type => :controller do
    
    shared_examples_for "a controller" do     
      controller do # anonymous subclass of ActionController::Base
        authentication_required region: :get_region
      
        def index
          head :ok
        end
      
        def get_region
          params[:region_id]
        end
      end
    end
    
    context "region id is not presented" do
      include_examples 'a controller'
      
      it "should throw an error" do
        controller.stub(:get_region) { nil }
        expect { get "index", region_id: 'europe' }.to raise_error(MonsoonOpenstackAuth::InvalidRegion)
      end
    end

    context "only token auth is allowed" do
      include_examples 'a controller'
      
      before :each do
        MonsoonOpenstackAuth.configuration.stub(:token_auth_allowed?){ true  }
        MonsoonOpenstackAuth.configuration.stub(:basic_atuh_allowed?){ false }
        MonsoonOpenstackAuth.configuration.stub(:sso_auth_allowed?)  { false }
        MonsoonOpenstackAuth.configuration.stub(:form_auth_allowed?) { false }
      end
      
      context "session token not presented" do  
        
        it "should redirect to main app's root path" do
          get "index", region_id: 'europe'  
          expect(response).to redirect_to(controller.main_app.root_path)
          expect(flash[:notice]).to eq "User is not authenticated!"
        end
        
        it "should authenticate user from auth token" do
          get "index", { region_id: 'europe' }, {"X-Auth-Token" => "asdfghjkl"}
        end
      end
      
      context "session token presented" do
        
      end
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
