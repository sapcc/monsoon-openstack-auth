require 'spec_helper'

describe MonsoonOpenstackAuth::Authentication::Controller, :type => :controller do
  before :each do
    MonsoonOpenstackAuth::Authentication::Session.stub(:check_authentication) {true}
  end
  
  context "skip authentication for an action" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {c.params[:organization]}, project: -> c {c.params[:project_id]}
      skip_authentication only: [:new]
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Authentication::Session).to receive(:check_authentication)
      get 'index', region_id: 'europe'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Authentication::Session).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "skip authentication for all actions" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization: -> c {c.params[:organization_id]}, project: -> c {c.params[:project_id]}
      skip_authentication
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Authentication::Session).not_to receive(:check_authentication)
      get 'index', region_id: 'europe'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Authentication::Session).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "ignore empty scope" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization: -> c {nil}, project: -> c {""}
    
      def index
        head :ok
      end
    
    end
    
    it "authentication should ignore empty organization and project" do
      expect(MonsoonOpenstackAuth::Authentication::Session).to receive(:check_authentication).with(controller,'europe', organization: nil, project: nil, raise_error:nil)
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
      expect(MonsoonOpenstackAuth::Authentication::Session).to receive(:check_authentication).with(controller,'europe', organization: "o-12345", project: "p-12345", raise_error:nil)
      get 'index', region_id: 'europe', organization_id: 'o-12345', project_id: 'p-12345'
    end
    
    it "authenticate with empty scope" do
      expect(MonsoonOpenstackAuth::Authentication::Session).to receive(:check_authentication).with(controller,'europe', organization: nil, project: nil, raise_error:nil)
      get 'index', region_id: 'europe', organization_id: '', project_id: ''
    end
      
  end
end