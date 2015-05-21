require_dependency "monsoon_openstack_auth/application_controller"

module MonsoonOpenstackAuth
  class SessionsController < ApplicationController
    skip_authentication
    
    def new
      @region = (params[:region_id] || MonsoonOpenstackAuth.configuration.default_region)
      
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
    end
  
    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      @domain = { name: params[:domain_name], id: params[:domain_id]}
      region = (params[:region_id] || MonsoonOpenstackAuth.configuration.default_region)
      redirect_to_url = MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(self,region,@username,@password, @domain)
      if redirect_to_url 
        redirect_to redirect_to_url, notice: 'Signed on!'
      else
        @error = 'Invalid username/password combination'
        render action: :new
      end
    end
  
    def destroy
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
      redirect_to main_app.root_path, notice: "Signed out!"
    end
  end
end