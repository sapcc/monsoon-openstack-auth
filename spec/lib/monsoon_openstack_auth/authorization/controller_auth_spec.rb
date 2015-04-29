require 'spec_helper'

class AuthorizeController < ApplicationController
  def index
    head :ok
  end

  def new
    head :ok
  end

  def update
    head :ok
  end

  def destroy
    head :ok
  end

  def authorization_forbidden error
    raise error
  end

end

class DomainController < AuthorizeController
  authentication_required region: -> c { 'europe' }
  authorization_actions_for :get_object, :except => [:update], :actions => {:index => 'list', :new => 'create', :destroy => 'delete'}
  authorization_actions :update => 'change'

  def update
    domain = get_domain
    authorization_action_for domain, params
    head :ok
  end

end

class ProjectController < AuthorizeController
  authentication_required region: -> c { 'europe' }
  authorization_actions :update => 'change', :destroy => 'delete', :index => 'list', :new => 'create'

  def index
    domain = get_domain
    authorization_action_for domain, params
    head :ok
  end

  def new
    domain = get_domain
    authorization_action_for domain, params
    head :ok
  end

  def update
    project = get_project
    authorization_action_for project, params
    head :ok
  end

  def destroy
    project = get_project
    authorization_action_for project, params
    head :ok
  end

end

describe DomainController, type: :controller do

  context "admin checks without domain instance" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return nil
      ActionController::Base.any_instance.stub(:get_object).and_return :Domain

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update
      expect(response.status).to eq(200)
    end

    it "should allow destroy" do
      get :destroy
      expect(response.status).to eq(200)
    end
  end

  context "admin checks where user does NOT own domain" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain
      ActionController::Base.any_instance.stub(:get_object).and_return Domain

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update
      expect(response.status).to eq(200)
    end

    it "should allow destroy" do
      get :destroy
      expect(response.status).to eq(200)
    end
  end

  context "member checks without domain instance" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return nil
      ActionController::Base.any_instance.stub(:get_object).and_return 'Domain'

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow update" do
      expect { get :update, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      # get :destroy, region_id: 'europe', :target => @target
      expect { get :destroy, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "member checks where user does NOT own domain" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain
      ActionController::Base.any_instance.stub(:get_object).and_return 'Domain'

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow update" do
      expect { get :update, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      # get :destroy, region_id: 'europe', :target => @target
      expect { get :destroy, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "member checks where user owns domain" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain
      ActionController::Base.any_instance.stub(:get_object).and_return 'Domain'

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      # get :destroy, region_id: 'europe', :target => @target
      expect { get :destroy, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end
end


describe ProjectController, type: :controller do

  context "admin check without project instance" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }

      @current_user = FactoryGirl.build_stubbed(:user, :admin)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @domain = FactoryGirl.build_stubbed(:domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain


      routes.draw do
        get "index" => "project#index"
        post "new" => "project#new"
        put "update" => "project#update"
        delete "destroy" => "project#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
    end

    it "should allow creation" do
      get :new, region_id: 'europe'
    end

  end

  context "member check when user owns domain" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }

      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      ActionController::Base.any_instance.stub(:get_object).and_return Project

      @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain


      routes.draw do
        get "index" => "project#index"
        post "new" => "project#new"
        put "update" => "project#update"
        delete "destroy" => "project#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe'
    end

    it "should allow creation" do
      get :new, region_id: 'europe'
    end

  end

  context "member checks where user owns project" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @project = FactoryGirl.build_stubbed(:project, :member_project)
      ActionController::Base.any_instance.stub(:get_project).and_return @project
      ActionController::Base.any_instance.stub(:get_object).and_return 'Project'


      routes.draw do
        get "index" => "project#index"
        post "new" => "project#new"
        put "update" => "project#update"
        delete "destroy" => "project#destroy"
      end
    end

    it "should allow update" do
      get :update, region_id: 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      get :destroy, region_id: 'europe'
      expect(response.status).to eq(200)
    end
  end
  context "member checks where user does NOT own project" do

    before (:each) do
      MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
      MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
      MonsoonOpenstackAuth.configuration.debug = true
      MonsoonOpenstackAuth.load_policy
    end

    before(:each) do
      MonsoonOpenstackAuth::Session.stub(:check_authentication) { true }
      @current_user = FactoryGirl.build_stubbed(:user, :member)
      ActionController::Base.any_instance.stub(:current_user).and_return @current_user

      @project = FactoryGirl.build_stubbed(:project)
      ActionController::Base.any_instance.stub(:get_project).and_return @project
      ActionController::Base.any_instance.stub(:get_object).and_return 'Project'


      routes.draw do
        get "index" => "project#index"
        post "new" => "project#new"
        put "update" => "project#update"
        delete "destroy" => "project#destroy"
      end
    end

    it "should allow update" do
      expect { get :update, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      expect { get :destroy, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

end

