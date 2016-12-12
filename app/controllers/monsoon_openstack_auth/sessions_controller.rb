require_dependency "monsoon_openstack_auth/application_controller"

module MonsoonOpenstackAuth
  class SessionsController < ActionController::Base
        
    def new
      @domain_id = params[:domain_id]
      @domain_name = params[:domain_name]
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
      reset_session
      session[:after_login_url] = params[:after_login]
    end
  
    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      @domain_id = params[:domain_id].blank? ? nil : params[:domain_id]
      @domain_name = params[:domain_name].blank? ? nil : params[:domain_name]
      
      after_login_url = (params[:after_login] || session[:after_login_url] || main_app.root_url(domain_id: (@domain_id || @domain_name)))
      if MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(self,@username,@password, @domain_id,@domain_name) 
        redirect_to after_login_url
      else
        @error = 'Invalid username/password combination'
        flash.now[:alert] = @error
        render action: :new
      end
    end
  
    def destroy
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
      reset_session
      logout_url = (params[:redirect_to] || self.main_app.root_url)  
      redirect_to logout_url
    end
  end
end