require_dependency "monsoon_identity/application_controller"

module MonsoonIdentity
  class SessionsController < ApplicationController
    def new
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonIdentity.configuration.form_auth_allowed?
      MonsoonIdentity::Session.logout(self)
    end
  
    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonIdentity.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      redirect_to_url = MonsoonIdentity::Session.create_from_login_form(self,params[:region_id],@username,@password)
      if redirect_to_url 
        redirect_to redirect_to_url, notice: 'Signed on!'
      else
        @error = 'Invalid username/password combination'
        render action: :new
      end
    end
  
    def destroy
      MonsoonIdentity::Session.logout(self)
      redirect_to main_app.root_path, notice: "Signed out!"
    end
  end
end