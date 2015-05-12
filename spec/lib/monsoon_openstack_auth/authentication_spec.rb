require 'spec_helper'

describe MonsoonOpenstackAuth::Authentication, :type => :controller do
  before :each do
    auth_session = double("auth_session")
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
      get 'index', region_id: 'europe'
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
      get 'index', region_id: 'europe'
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
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller,'europe', domain: nil, project: nil, raise_error:nil)
      get 'index', region_id: 'europe'
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
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller,'europe', domain: "o-12345", project: "p-12345", raise_error:nil)
      get 'index', region_id: 'europe', organization_id: 'o-12345', project_id: 'p-12345'
    end
    
    it "authenticate with empty scope" do
      expect(MonsoonOpenstackAuth::Authentication::AuthSession).to receive(:check_authentication).with(controller,'europe', domain: nil, project: nil, raise_error:nil)
      get 'index', region_id: 'europe', organization_id: '', project_id: ''
    end
      
  end
end