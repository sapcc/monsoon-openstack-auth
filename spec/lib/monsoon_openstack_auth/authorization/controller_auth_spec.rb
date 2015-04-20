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
end

class DomainController < AuthorizeController
  authentication_required region: -> c { 'europe' }
  authorization_required :except => [:create]
  authorization_actions :index => 'list', :update => 'change'
end

class ProjectController < AuthorizeController
  authentication_required region: -> c { 'europe' }
  authorization_required
  authorization_actions :index => 'list', :update => 'change'
end

describe DomainController, type: :controller do

  context "admin checks" do

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
      @target = {domain_id: "#{@domain.domain_id}"}

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

  context "member checks" do

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
      @target = {domain_id: "#{@domain.domain_id}"}

      routes.draw do
        get "index" => "domain#index"
        post "new" => "domain#new"
        put "update" => "domain#update"
        delete "destroy" => "domain#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update, region_id: 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      # get :destroy, region_id: 'europe', :target => @target
      expect { get :destroy, region_id: 'europe', :target => @target }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end
end

describe ProjectController, type: :controller do

  context "admin checks" do

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

    it "should allow update" do
      get :update, region_id: 'europe'
    end

    it "should allow destroy" do
      get :destroy, region_id: 'europe'
    end
  end

  context "member checks" do

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
      @project = FactoryGirl.build_stubbed(:project, :member_project)
      @target = {domain_id: "#{@domain.domain_id}", project_id: "#{@project.project_id}"}

      routes.draw do
        get "index" => "project#index"
        post "new" => "project#new"
        put "update" => "project#update"
        delete "destroy" => "project#destroy"
      end
    end

    it "should allow index" do
      get :index, region_id: 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should allow creation" do
      get :new, :region_id => 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should allow update" do
      get :update, region_id: 'europe', :target => @target
      expect(response.status).to eq(200)
    end

    it "should NOT allow destroy" do
      # get :destroy, region_id: 'europe', :target => @target
      expect { get :destroy, region_id: 'europe', :target => @target }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    end

  end

end

