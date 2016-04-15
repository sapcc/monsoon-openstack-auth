require_dependency "monsoon_openstack_auth/application_controller"

module MonsoonOpenstackAuth
  class SessionsController < ActionController::Base
        
    def new
      @domain_id = params[:domain_id]
      @domain_name = params[:domain_name]
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
    end
  
    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      @domain_id = params[:domain_id]
      @domain_name = params[:domain_name]
      redirect_to_url = MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(self,@username,@password, @domain_id,@domain_name)
      if redirect_to_url 
        redirect_to redirect_to_url#, notice: 'Signed on!'
      else
        @error = 'Invalid username/password combination'
        flash.now[:alert] = @error
        render action: :new
      end
    end
  
    def destroy
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
      logout_url = (params[:redirect_to] || self.main_app.root_url)  
      redirect_to logout_url
    end
  end
end