# frozen_string_literal: true

require_dependency 'monsoon_openstack_auth/application_controller'

module MonsoonOpenstackAuth
  # Sessions Handler
  class SessionsController < ActionController::Base
    before_action :load_auth_params, except: %i[destroy]

    def new
      unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
        redirect_to main_app.root_path, alert: 'Not allowed!'
        return
      end

      MonsoonOpenstackAuth::Authentication::AuthSession.logout(
        self, (@domain_id || @domain_name)
      )
    end

    def create
      unless MonsoonOpenstackAuth.configuration.form_auth_allowed?
        redirect_to main_app.root_path, alert: 'Not allowed!'
        return
      end

      after_login_url = (params[:after_login] || main_app.root_url(
        domain_id: (@domain_id || @domain_name)
      ))

      auth_session = MonsoonOpenstackAuth::Authentication::AuthSession
                     .create_from_login_form(
                       self, @username, @password,
                       domain_id: @domain_id, domain_name: @domain_name
                     )

      if auth_session
        if !@two_factor || MonsoonOpenstackAuth::Authentication::AuthSession.two_factor_cookie_valid?(self)
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
      after_login_url = (params[:after_login] || main_app.root_url(
        domain_id: (@domain_id || @domain_name)
      ))

      @error = begin
        unless MonsoonOpenstackAuth::Authentication::AuthSession.check_two_factor(self, @username, @passcode)
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
      MonsoonOpenstackAuth::Authentication::AuthSession.logout(
        self, params[:domain_name]
      )
      logout_url = (params[:redirect_to] || main_app.root_url)
      redirect_to logout_url
    end

    private

    def load_auth_params
      @username = params[:username]
      @password = params[:password]
      @domain_id = params[:domain_id]
      @domain_name = params[:domain_name]
      @two_factor = params[:two_factor].to_s == 'true'
    end
  end
end
