require 'spec_helper'

describe MonsoonOpenstackAuth::Authorization::PolicyEngine do

  describe "Authorization Policy" do

    before() do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.load_policy
      @policy_engine = MonsoonOpenstackAuth.policy_engine

    end

    context "missing rule params" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :admin)
        @policy = @policy_engine.policy(@current_user)
      end

      it "raises no error if empty params" do
        expect{
          @policy.enforce(["owner"],{})
        }.not_to raise_error #(MonsoonOpenstackAuth::Authorization::RuleExecutionError)
      end
    end

    context "policy gets enforced when user is admin" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :admin)
        @action = [x.metadata[:description_args].first]
        @policy = @policy_engine.policy(@current_user)
      end

      it "returns true if user is admin" do
        expect(@current_user.admin?).to eq(true)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@action)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect(@policy.enforce(@action)).to eq(true)
      end
    end

    context "policy gets enforced when user is domain member/owner" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @params = {:domain => {:id => @domain.id},:project => {:id => @project.id}}
        @policy = @policy_engine.policy(@current_user)
      end
      it "returns false if user is domain member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect(@policy.enforce(@action)).to eq(false)
      end
    end

    context "policy gets enforced when user is domain and project member/owner" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @params = Hashie::Mash.new({:domain => {:id => @domain.id},:project => {:id => @project.id}})
        @policy = @policy_engine.policy(@current_user)
      end
      it "returns false if user is project member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
    end

    context "policy get enforced when user is neither admin nor member" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :neither_admin_nor_member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain)
        @project = FactoryGirl.build_stubbed(:project)
        @params = Hashie::Mash.new({:domain => {:id => @domain.id},:project => {:id => @project.id}})
        @policy = @policy_engine.policy(@current_user)
      end
      it "returns false if user is neither admin nor member" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect(@policy.enforce(@action, @params)).to eq(false)
      end
    end
  end
end
