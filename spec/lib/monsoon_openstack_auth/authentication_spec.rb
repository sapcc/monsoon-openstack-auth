require 'spec_helper'

describe MonsoonOpenstackAuth::Authentication, :type => :controller do
  before :each do
    auth_session = double("auth_session").as_null_object
    auth_session.stub(:user).and_return(FactoryGirl.build_stubbed(:user, :member))
    MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
  end
  
  context "skip authentication for an action" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, domain: -> c {c.params[:domain_id]}, project: -> c {c.params[:project_id]}
      skip_authentication only: [:new]
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication)
      get 'index'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "skip authentication for all actions" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, domain: -> c {c.params[:domain_id]}, project: -> c {c.params[:project_id]}
      skip_authentication
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).not_to receive(:check_authentication)
      get 'index'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "ignore empty scope" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, domain: -> c {nil}, project: -> c {""}
    
      def index
        head :ok
      end
    
    end
    
    it "authentication should ignore empty domain and project" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller, domain: nil, domain_name: nil, project: nil, raise_error:nil)
      get 'index'
    end
      
  end
  
  context "scope not nil" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization: :get_org, project: -> c {c.params[:project_id]}
    
      def index
        head :ok
      end
      
      def get_org
        params[:organization_id]
      end
    end
    
    it "authenticate with scope 0-12345 and p-12345" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller, domain: "o-12345", domain_name: nil, project: "p-12345", raise_error:nil)
      get 'index', organization_id: 'o-12345', project_id: 'p-12345'
    end
    
    it "authenticate with empty scope" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller, domain: nil, domain_name: nil, project: nil, raise_error:nil)
      get 'index', organization_id: '', project_id: ''
    end
    
  end
  
  
  context "api_authentication_required" do
    before :each do
      #@fog_driver = double("fog driver").as_null_object
      #Fog::IdentityV3::OpenStack.stub(:new).and_return(@fog_driver)
      allow(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).and_call_original
    end
    
    controller do # anonymous subclass of ActionController::Base
      api_authentication_required domain: -> c {c.params[:domain_id]}, project: -> c {c.params[:project_id]}
    
      def index
        head :ok
      end
    end
      
    it "authenticate without redirect" do 
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller, domain: "aaa", domain_name: nil, project: "bbb", raise_error:true).and_return(nil)
      get 'index', domain_id: 'aaa', project_id: 'bbb'
    end
    
    it "should raise a not_authorized_error if not authenticated" do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(false)
      expect { get 'index', domain_id: 'aaa', project_id: 'bbb' }.to raise_error
    end
    
    
    it "should raise not_authorized_error on forbidden scope " do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:rescope_token).and_raise(MonsoonOpenstackAuth::Authentication::NotAuthorized)
    
      expect { get 'index', domain_id: 'aaa', project_id: 'bbb' }.to raise_error
    end
    
    it "should not raise a not_authorized_error" do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:rescope_token).and_return(true)

      expect { get 'index', domain_id: 'aaa', project_id: 'bbb' }.not_to raise_error
    end
    
    it "should not raise a not_authorized_error" do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:rescope_token).and_return(false)

      expect { get 'index', domain_id: 'aaa', project_id: 'bbb' }.not_to raise_error
    end
      
  end
  
  context "authentication_required" do
    before :each do
      allow(MonsoonOpenstackAuth::ApiClient).to receive(:new).and_return(double('api client').as_null_object)
      allow(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).and_call_original
    end
    
    controller do # anonymous subclass of ActionController::Base
      authentication_required domain: -> c {c.params[:domain_id]}, project: -> c {c.params[:project_id]}
    
      def index
        head :ok
      end
    end
  
    it "do not redirect -> raise error" do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(true)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:rescope_token).and_raise(MonsoonOpenstackAuth::Authentication::NotAuthorized)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:redirect_to_login_form).and_return true

      expect {get 'index', domain_id: 'aaa', project_id: 'bbb'}.to raise_error
    end

    it "redirect to login form" do
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:authenticated?).and_return(false)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:rescope_token).and_raise(MonsoonOpenstackAuth::Authentication::NotAuthorized)
      allow_any_instance_of(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:redirect_to_login_form).and_return true

      expect { get 'index', domain_id: 'aaa', project_id: 'bbb' }.not_to raise_error
    end
  end  
  
  context "do not rescope token" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required domain: -> c {c.params[:domain_id]}, 
                              project: -> c {c.params[:project_id]}, 
                              rescope: false
                              
      def index; head :ok; end
    end
    
    it "should call after_login callback before rescoping" do
      auth_session = double("auth_session").as_null_object
      MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
      
      expect(auth_session).not_to receive(:rescope_token)
      
      get 'index', domain_id: 'aaa', project_id: 'bbb'
    end
  end
  
  context "explicitly rescope token" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required domain: -> c {c.params[:domain_id]}, 
                              project: -> c {c.params[:project_id]}, 
                              rescope: false
      
      before_filter :authentication_rescope_token                        
      def index; head :ok; end
    end
    
    it "should call after_login callback before rescoping" do
      auth_session = double("auth_session").as_null_object
      MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
      
      expect(auth_session).to receive(:rescope_token)
      
      get 'index', domain_id: 'aaa', project_id: 'bbb'
    end
  end
  
  context "implicitly rescope token after authentication" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required domain: -> c {c.params[:domain_id]}, 
                              project: -> c {c.params[:project_id]}
      
      def index; head :ok; end
    end
    
    it "should call after_login callback before rescoping" do
      auth_session = double("auth_session").as_null_object
      MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
      
      expect(auth_session).to receive(:rescope_token)
      
      get 'index', domain_id: 'aaa', project_id: 'bbb'
    end
  end
end