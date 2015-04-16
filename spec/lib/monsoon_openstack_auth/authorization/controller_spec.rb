require 'spec_helper'

describe MonsoonOpenstackAuth::Controller, :type => :controller do

  before :each do
    MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
    MonsoonOpenstackAuth.configuration.stub(:debug).and_return true
    MonsoonOpenstackAuth.configuration.stub(:authorization_policy_file).and_return "spec/config/policy_test.json"
  end

  context "authorization filter all" do
    #before { skip }
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required
      authorization_actions :change => 'update', :index => 'list'

      def index
        head :ok
      end

      def new
        head :ok
      end

      def change
        head :ok
      end
    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user
    end

    it "should require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to receive(:enforce)
      get 'index', region_id: 'europe'
    end

    it "should require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to receive(:enforce)
      get 'new', region_id: 'europe'
    end

  end

  context "authorization filter except" do

    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required :except => [:index, :show]

      def index
        head :ok
      end

      def new
        head :ok
      end

      def change
        head :ok
      end
    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user
    end

    it "should NOT require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to_not receive(:enforce)
      get 'index', region_id: 'europe'
    end

    it "should require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to receive(:enforce)
      get 'new', region_id: 'europe'
    end

  end

  context "authorization filter only" do
    #before { skip }
    controller  do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required :only => [:new]

      def index
        head :ok
      end

      def new
        head :ok
      end

      def change
        head :ok
      end
    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user
    end

    it "should NOT require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to_not receive(:enforce)
      get 'index', region_id: 'europe'
    end

    it "should require authorization" do
      expect(MonsoonOpenstackAuth::Policy.instance).to receive(:enforce)
      get 'new', region_id: 'europe'
    end
  end


end