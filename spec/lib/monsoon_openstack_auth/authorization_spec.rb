require 'spec_helper'

describe MonsoonOpenstackAuth::Authorization, :type => :controller do

  before :each do
    auth_session = double("auth_session")
    auth_session.stub(:user).and_return(FactoryGirl.build_stubbed(:user, :member))
    MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
    MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
    MonsoonOpenstackAuth.load_policy
  end

  context "authorization filter all" do
    #before { skip }
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_actions_for :get_domain
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

      def authorization_forbidden error
        raise error
      end

    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      controller.stub(:current_user).and_return @current_user
      @domain = FactoryGirl.build_stubbed(:domain)
      controller.stub(:get_domain).and_return @domain
    end

    it "should require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'index', region_id: 'europe'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new', region_id: 'europe'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "authorization filter except" do
    #before { skip }

    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_actions_for :get_domain, :except => [:index, :show]

      def index
        head :ok
      end

      def new
        head :ok
      end

      def change
        head :ok
      end

      def authorization_forbidden error
        raise error
      end

    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      controller.stub(:current_user).and_return @current_user
      @domain = FactoryGirl.build_stubbed(:domain)
      controller.stub(:get_domain).and_return @domain
    end

    it "should NOT require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).not_to receive(:enforce)
        get 'index', region_id: 'europe'
      }.not_to raise_error
    end

    it "should require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new', region_id: 'europe'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "authorization filter only" do
    #before { skip }

    controller  do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, organization_id: -> c { c.params[:organization_id] }, project_id: -> c { c.params[:project_id] }
      authorization_actions_for :get_domain, :only => [:new]

      def index
        head :ok
      end

      def new
        head :ok
      end

      def change
        head :ok
      end

      def authorization_forbidden error
        raise error
      end

    end

    before :each do
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      controller.stub(:current_user).and_return @current_user
      @domain = FactoryGirl.build_stubbed(:domain)
      controller.stub(:get_domain).and_return @domain
    end

    it "should NOT require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to_not receive(:enforce)
        get 'index', region_id: 'europe'
      }.not_to raise_error
    end

    it "should require authorization" do
      expect{
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new', region_id: 'europe'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)

    end
  end


end