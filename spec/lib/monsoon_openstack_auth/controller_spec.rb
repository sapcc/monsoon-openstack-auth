require 'spec_helper'

describe MonsoonOpenstackAuth::Controller, :type => :controller do
  before :each do
    MonsoonOpenstackAuth::Session.stub(:check_authentication) {true}
  end
  
  context "skip authentication for an action" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {c.params[:organization_id]}, project_id: -> c {c.params[:project_id]}
      skip_authentication only: [:new]
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Session).to receive(:check_authentication)
      get 'index', region_id: 'europe'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Session).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "skip authentication for all actions" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {c.params[:organization_id]}, project_id: -> c {c.params[:project_id]}
      skip_authentication
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end

    it "should require authentication" do
      expect(MonsoonOpenstackAuth::Session).not_to receive(:check_authentication)
      get 'index', region_id: 'europe'
    end
      
    it "should skip authentication" do
      expect(MonsoonOpenstackAuth::Session).not_to receive(:check_authentication)
      get 'new'
    end
  end
  
  context "ignore empty scope" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c {c.params[:region_id]}, organization_id: -> c {nil}, project_id: -> c {""}
    
      def index
        head :ok
      end
    
      def new
        head :ok
      end
    end
    
    it "authentication should ignore empty organization and project" do
      expect(MonsoonOpenstackAuth::Session).to receive(:check_authentication).with(controller,'europe', organization: nil, project: nil)
      get 'index', region_id: 'europe'
    end
      
  end
end