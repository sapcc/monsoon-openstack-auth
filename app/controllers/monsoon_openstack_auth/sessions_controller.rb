require_dependency "monsoon_openstack_auth/application_controller"

module MonsoonOpenstackAuth
  class SessionsController < ApplicationController
    def new
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      MonsoonOpenstackAuth::Session.logout(self)
    end
  
    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      redirect_to_url = MonsoonOpenstackAuth::Session.create_from_login_form(self,params[:region_id],@username,@password)
      if redirect_to_url 
        redirect_to redirect_to_url, notice: 'Signed on!'
      else
        @error = 'Invalid username/password combination'
        render action: :new
      end
    end
  
    def destroy
      MonsoonOpenstackAuth::Session.logout(self)
      redirect_to main_app.root_path, notice: "Signed out!"
    end
  end
end