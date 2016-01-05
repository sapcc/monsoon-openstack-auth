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
    authorization_action_for domain
    head :ok
  end

  def new
    domain = get_domain
    authorization_action_for domain
    head :ok
  end

  def update
    project = get_project
    authorization_action_for project
    head :ok
  end

  def destroy
    project = get_project
    authorization_action_for project
    head :ok
  end

end

describe DomainController, type: :controller do
  let(:member){FactoryGirl.build_stubbed(:user, :member)}
  let(:admin){FactoryGirl.build_stubbed(:user, :admin)}
  
  before (:each) do
    MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
    MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
    MonsoonOpenstackAuth.configuration.debug = true
    MonsoonOpenstackAuth.load_policy
    
    auth_session = double("auth_session").as_null_object
    auth_session.stub(:user).and_return(FactoryGirl.build_stubbed(:user, :member))
    MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
    MonsoonOpenstackAuth.stub(:api_client)
    
    routes.draw do
      get "index" => "domain#index"
      post "new" => "domain#new"
      put "update" => "domain#update"
      delete "destroy" => "domain#destroy"
    end
  end

  context "admin checks without domain instance" do

    before (:each) do      
      controller.stub(:current_user).and_return(admin)
      controller.stub(:get_domain).and_return nil
      controller.stub(:get_object).and_return :Domain
    end

    it "should allow index" do
      get :index
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
      controller.stub(:current_user).and_return(admin)
      domain = FactoryGirl.build_stubbed(:domain)
      controller.stub(:get_domain).and_return domain
      controller.stub(:get_object).and_return Domain
    end

    it "should allow index" do
      get :index
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
      controller.stub(:current_user).and_return(member)
      controller.stub(:get_domain).and_return nil
      controller.stub(:get_object).and_return 'Domain'
    end

    it "should allow index" do
      get :index
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow update" do
      expect { get :update }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      # get :destroy, :target => @target
      expect { get :destroy }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "member checks where user does NOT own domain" do

    before (:each) do
      controller.stub(:current_user).and_return(member)
      controller.stub(:get_domain).and_return(FactoryGirl.build_stubbed(:domain))
      controller.stub(:get_object).and_return 'Domain'
    end

    it "should allow index" do
      get :index
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should NOT allow update" do
      expect { get :update }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      # get :destroy, :target => @target
      expect { get :destroy }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

  context "member checks where user owns domain" do

    before (:each) do
      controller.stub(:current_user).and_return(member)
      controller.stub(:get_domain).and_return(FactoryGirl.build_stubbed(:domain, :member_domain))
      controller.stub(:get_object).and_return 'Domain'
    end

    it "should allow index" do
      get :index
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe'
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      # get :destroy, :target => @target
      expect { get :destroy }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end
end


describe ProjectController, type: :controller do
  let(:member){FactoryGirl.build_stubbed(:user, :member)}
  let(:admin){FactoryGirl.build_stubbed(:user, :admin)}
  
  before (:each) do
    MonsoonOpenstackAuth.configuration.authorization.policy_file_path = Rails.root.join("../config/policy_test.json")
    MonsoonOpenstackAuth.configuration.authorization.context = 'identity'
    MonsoonOpenstackAuth.configuration.debug = true
    MonsoonOpenstackAuth.load_policy
    
    auth_session = double("auth_session").as_null_object
    auth_session.stub(:user).and_return(FactoryGirl.build_stubbed(:user, :member))
    MonsoonOpenstackAuth::Authentication::AuthSession.stub(:check_authentication) {auth_session}
    MonsoonOpenstackAuth.stub(:api_client)
    
    routes.draw do
      get "index" => "project#index"
      post "new" => "project#new"
      put "update" => "project#update"
      delete "destroy" => "project#destroy"
    end
  end

  context "admin check without project instance" do
    before(:each) do
      controller.stub(:current_user).and_return(admin)
      controller.stub(:get_domain).and_return(FactoryGirl.build_stubbed(:domain))
    end

    it "should allow index" do
      get :index
    end

    it "should allow creation" do
      get :new
    end

  end

  context "member check when user owns domain" do

    before (:each) do
      controller.stub(:current_user).and_return member
      controller.stub(:get_object).and_return Project
      controller.stub(:get_domain).and_return(FactoryGirl.build_stubbed(:domain, :member_domain))
    end

    it "should allow index" do
      get :index
    end

    it "should allow creation" do
      get :new
    end

  end

  context "member checks where user owns project" do

    before (:each) do
      controller.stub(:current_user).and_return member
      controller.stub(:get_project).and_return FactoryGirl.build_stubbed(:project, :member_project)
      controller.stub(:get_object).and_return 'Project'
    end

    it "should allow update" do
      get :update
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      get :destroy
      expect(response.status).to eq(200)
    end
  end
  context "member checks where user does NOT own project" do

    before (:each) do
      controller.stub(:current_user).and_return member
      controller.stub(:get_project).and_return FactoryGirl.build_stubbed(:project)
      controller.stub(:get_object).and_return 'Project'
    end

    it "should allow update" do
      expect { get :update }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

    it "should NOT allow destroy" do
      expect { get :destroy }.to raise_error(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

end

