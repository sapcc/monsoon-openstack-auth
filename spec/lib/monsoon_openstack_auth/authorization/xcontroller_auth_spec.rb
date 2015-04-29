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
  authorization_actions_for :Domain, :except => [:create], :actions => { :update => 'list' }
  authorization_actions :index => 'list' #, :update => 'change'
end
#
# class ProjectController < AuthorizeController
#   authentication_required region: -> c { 'europe' }
#   authorization_actions_for :get_project, :name => "project", :only => [:update, :destroy]
#   authorization_actions :index => 'list', :update => 'change'
#
#   def index
#     @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
#     authorization_action_for @domain , params
#     head :ok
#   end
#
#   def new
#     @domain = FactoryGirl.build_stubbed(:domain, :member_domain)
#     authorization_action_for @domain, params
#     head :ok
#   end
#
# end

describe DomainController, type: :controller do


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
      ActionController::Base.any_instance.stub(:get_domain).and_return @domain

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

    # it "should allow creation" do
    #   get :new, :region_id => 'europe'
    #   expect(response.status).to eq(200)
    # end
    #
    # it "should allow update" do
    #   get :update, region_id: 'europe'
    #   expect(response.status).to eq(200)
    # end
    #
    # it "should NOT allow destroy" do
    #   # get :destroy, region_id: 'europe', :target => @target
    #   expect { get :destroy, region_id: 'europe' }.to raise_exception(MonsoonOpenstackAuth::Authorization::SecurityViolation)
    # end

  end


end

