require 'spec_helper'

describe MonsoonOpenstackAuth::Authorization::PolicyEngine do

  describe "User authorizations" do

    before :all do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.load_policy
      @policy_engine = MonsoonOpenstackAuth.policy_engine
    end

    context "user allowed actions when user is admin" do

      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :admin)
        @action = [x.metadata[:description_args].first]
      end

      it "returns true if user is admin" do
        expect(@current_user.admin?).to eq(true)
      end

      it "identity:domain_list" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
      it "identity:project_list" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
      it "identity:project_create" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
      it "identity:project_change" do
        expect(@current_user.is_allowed?(@action,project:OpenStruct.new(id:1))).to eq(true)
      end
      it "identity:project_default_check" do
        expect(@current_user.is_allowed?(@action)).to eq(true)
      end
    end

    context "user allowed actions when user is domain member/owner" do
      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @params = Hashie::Mash.new({:domain => {:id => @domain.id}, :project => {:id => @project.id}})
      end
      it "returns false if user is domain member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_default_check" do
        expect(@current_user.is_allowed?(@action)).to eq(false)
      end
    end

    context "user allowed actions when user is membe" do

      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
        @project = FactoryGirl.build_stubbed(:project, :member_project)
        @params = Hashie::Mash.new({:domain => {:id => @domain.id}, :project => {:id => @project.id}})
      end
      it "returns false if user is project member/owner" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:domain_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:project_default_check" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
    end

    context "user allowed actions when user is neither admin nor member" do

      before :each do |x|
        @current_user = FactoryGirl.build_stubbed(:user, :neither_admin_nor_member)
        @action = [x.metadata[:description_args].first]
        @domain = FactoryGirl.build_stubbed(:domain)
        @project = FactoryGirl.build_stubbed(:project)
        @params = Hashie::Mash.new({:domain => {:id => @domain.id}, :project => {:id => @project.id}})
      end
      it "returns false if user is neither admin nor member" do
        expect(@current_user.admin?).to eq(false)
      end

      it "identity:domain_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
      it "identity:domain_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(true)
      end
      it "identity:domain_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
      it "identity:project_list" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
      it "identity:project_create" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
      it "identity:project_change" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
      it "identity:project_default_check" do
        expect(@current_user.is_allowed?(@action, @params)).to eq(false)
      end
    end
  end
end
