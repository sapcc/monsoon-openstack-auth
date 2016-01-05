require 'spec_helper'

describe MonsoonOpenstackAuth::Authorization, :type => :controller do

  before :each do
    auth_session = double("auth_session").as_null_object
    auth_session.stub(:user).and_return(FactoryGirl.build_stubbed(:user, :member))
    MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) { auth_session }
    MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
    MonsoonOpenstackAuth.load_policy
    MonsoonOpenstackAuth.stub(:api_client)
  end

  context "authorization filter all" do
    #before { skip }
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, domain: -> c { c.params[:domain_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required

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
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'index'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should require authorization" do
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "authorization filter except" do
    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, domain: -> c { c.params[:domain_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required except: [:index]

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
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).not_to receive(:enforce)
        get 'index'
      }.not_to raise_error
    end

    it "should require authorization" do
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "authorization filter only" do
    #before { skip }

    controller do # anonymous subclass of ActionController::Base
      authentication_required region: -> c { c.params[:region_id] }, domain: -> c { c.params[:domain_id] }, project_id: -> c { c.params[:project_id] }
      authorization_required except: [:index]

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
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to_not receive(:enforce)
        get 'index'
      }.not_to raise_error
    end

    it "should require authorization" do
      expect {
        expect_any_instance_of(MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy).to receive(:enforce)
        get 'new'
      }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)

    end
  end

  context "check permissions" do
    controller do
    end
    params = {"action" => "index", "controller" => "api/v3/credentials", "page" => "1", "per_page" => "10"}


    it "should add relevant params to policy params" do
      additional_params = {"user_id" => "1", "id" => "2"}
      stub_const("User", double('User').as_null_object)
      stub_const("Credential", double('Credential').as_null_object)

      policy_params = ::MonsoonOpenstackAuth::Authorization.build_policy_params(controller, additional_params.merge(params))

      additional_params.each do |name, value|
        expect(policy_params.key?(name.to_sym)).to eq(true)
      end

      expect(policy_params[:target].key?(:user)).to eq(true)
    end

    it "should determine rule name" do
      allow(MonsoonOpenstackAuth::Authorization).to receive(:authorization_action_map).and_return({})

      app_name = MonsoonOpenstackAuth.configuration.authorization.context
      rule_name = -> controller_name, action_name { MonsoonOpenstackAuth::Authorization.determine_rule_name(controller_name, action_name) }

      expect(rule_name.call("credentials", "index")).to eq("#{app_name}:credential_index")
      expect(rule_name.call("users", "create")).to eq("#{app_name}:user_create")
      expect(rule_name.call("projects", "edit")).to eq("#{app_name}:project_edit")
      expect(rule_name.call("users", "destroy")).to eq("#{app_name}:user_destroy")
      expect(rule_name.call("users", "show")).to eq("#{app_name}:user_show")
    end

    it "should determine rule name regarding action mapping" do
      allow(MonsoonOpenstackAuth::Authorization).to receive(:authorization_action_map).and_return({
                                                                                                      :index => 'list',
                                                                                                      :show => 'read',
                                                                                                      :new => 'create',
                                                                                                      :create => 'create',
                                                                                                      :edit => 'update',
                                                                                                      :update => 'update',
                                                                                                      :destroy => 'delete'
                                                                                                  })

      app_name = MonsoonOpenstackAuth.configuration.authorization.context
      rule_name = -> controller_name, action_name { MonsoonOpenstackAuth::Authorization.determine_rule_name(controller_name, action_name) }

      expect(rule_name.call("credentials", "index")).to eq("#{app_name}:credential_list")
      expect(rule_name.call("users", "create")).to eq("#{app_name}:user_create")
      expect(rule_name.call("projects", "edit")).to eq("#{app_name}:project_update")
      expect(rule_name.call("users", "destroy")).to eq("#{app_name}:user_delete")
      expect(rule_name.call("users", "show")).to eq("#{app_name}:user_read")
    end

    describe "enforce_permissions" do
      policy_class = MonsoonOpenstackAuth::Authorization::PolicyEngine::Policy

      before :each do
        controller.stub(:current_user).and_return FactoryGirl.build_stubbed(:user, :admin)
        allow(MonsoonOpenstackAuth.configuration.authorization).to receive(:trace_enabled).and_return false
        allow_any_instance_of(policy_class).to receive(:enforce).and_return(true)
      end

      it "should call policy engine" do
        expect_any_instance_of(policy_class).to receive(:enforce).with(["identity:credential_list"], {})
        controller.enforce_permissions("identity:credential_list", {})
      end

      it "should complete rule_name if context is missing" do
        expect_any_instance_of(policy_class).to receive(:enforce).with(["identity:credential_list"], {})
        controller.enforce_permissions("credential_list", {})
      end

      it "should complete rule_name if context is missing and name is symbol" do
        expect_any_instance_of(policy_class).to receive(:enforce).with(["identity:credential_list"], {})
        controller.enforce_permissions(:credential_list, {})
      end

      it "should complete rule_name if no rule_name given" do
        controller.stub(:params).and_return({"action" => "index", "controller" => "credentials"})
        controller.stub(controller_name: 'credential', action_name: 'index')
        expect_any_instance_of(policy_class).to receive(:enforce).with(["identity:credential_index"], {user: anything()})
        controller.enforce_permissions({user: double('User')})
      end
    end
  end

end