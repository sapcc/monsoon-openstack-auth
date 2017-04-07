require_dependency "monsoon_openstack_auth/application_controller"

module MonsoonOpenstackAuth
  class SessionsController < ActionController::Base

    def new
      @domain_id = params[:domain_id]
      @domain_name = params[:domain_name]
      @two_factor = (params[:two_factor] && (params[:two_factor]=='true' or params[:two_factor]==true))

      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(self)
      reset_session
      session[:two_factor] = @two_factor
      session[:after_login_url] = params[:after_login]
    end

    def create
      redirect_to main_app.root_path, alert: 'Not allowed!' and return unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
      @username = params[:username]
      @password = params[:password]
      @domain_id = params[:domain_id].blank? ? nil : params[:domain_id]
      @domain_name = params[:domain_name].blank? ? nil : params[:domain_name]
      @two_factor = (params[:two_factor] && (params[:two_factor]=='true' or params[:two_factor]==true)) or session[:two_factor]

      after_login_url = (params[:after_login] || session[:after_login_url] || main_app.root_url(domain_id: (@domain_id || @domain_name)))
      if MonsoonOpenstackAuth::Authentication::AuthSession.create_from_login_form(self,@username,@password, domain_id: @domain_id, domain_name: @domain_name)
        if !@two_factor or MonsoonOpenstackAuth::Authentication::AuthSession.two_factor_cookie_valid?(self)
          redirect_to after_login_url
        else
          render action: :two_factor
        end
      else
        @error = 'Invalid username/password combination.'
        flash.now[:alert] = @error
        render action: :new
      end
    end

    def check_passcode
      @username = params[:username]
      @passcode = params[:passcode]
      @domain_id = params[:domain_id].blank? ? nil : params[:domain_id]
      @domain_name = params[:domain_name].blank? ? nil : params[:domain_name]

      after_login_url = (params[:after_login] || session[:after_login_url] || main_app.root_url(domain_id: (@domain_id || @domain_name)))

      @error = begin
        unless MonsoonOpenstackAuth::Authentication::AuthSession.check_two_factor(self,@username,@passcode)
          'Invalid SecurID Passcode.'
        else
          nil
        end
      rescue => e
        e.message
      end

      if @error
        flash.now[:alert] = @error
        render action: :two_factor
      else
        redirect_to after_login_url
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
