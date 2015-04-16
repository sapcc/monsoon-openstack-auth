require 'spec_helper'

describe MonsoonOpenstackAuth::Policy do

  describe "Authorization Policy" do

    before() do
      MonsoonOpenstackAuth.configuration.authorization_policy_file = Rails.root.join("../config/policy_test.json")
      @policy = MonsoonOpenstackAuth::Policy.instance
    end

    context "policy gets enforced when user is admin" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :admin)
        @action = [x.metadata[:description_args].first]
      end

      it "returns true if user is admin" do
        expect(@current_user.admin?).to eq(true)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect(@policy.enforce(@current_user, @action)).to eq(true)
      end
    end

    context "policy gets enforced when user is domain member/owner" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @target = Hashie::Mash.new({:target => {:domain_id => @domain.domain_id, :project_id => @project.project_id}})
      end
      it "returns false if user is domain member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect {@policy.enforce(@current_user, @action)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
    end

    context "policy gets enforced when user is domain and project member/owner" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @target =  Hashie::Mash.new({:target => {:domain_id => @domain.domain_id, :project_id => @project.project_id}})
      end
      it "returns false if user is project member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_list" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_create" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:project_change" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
    end

    context "policy get enforced when user is neither admin nor member" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :neither_admin_nor_member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain)
        @project = FactoryGirl.build_stubbed(:project)
        @target = {:domain_id => @domain.domain_id, :project_id => @project.project_id}
      end
      it "returns false if user is neither admin nor member" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
      it "identity:domain_create" do
        expect(@policy.enforce(@current_user, @action, @target)).to eq(true)
      end
      it "identity:domain_change" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
      it "identity:project_list" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
      it "identity:project_create" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
      it "identity:project_change" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
      it "identity:enforce_default_needs_admin_role" do
        expect {@policy.enforce(@current_user, @action, @target)}.to raise_exception(MonsoonOpenstackAuth::SecurityViolation)
      end
    end
  end
end
