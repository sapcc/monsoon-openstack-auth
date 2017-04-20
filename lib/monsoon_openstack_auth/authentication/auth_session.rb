module MonsoonOpenstackAuth
  module Authentication
    class AuthSession
      attr_reader :session_store

      class << self
        TWO_FACTOR_AUTHENTICATION = 'two_factor_authentication'

        def load_user_from_session(controller)
          session = AuthSession.new(controller,session_store(controller), nil)
          session.validate_session_token
          return session
        end

        # check if valid token, basic auth, sso or session token is presented
        def check_authentication(controller, scope_and_options={})
          raise_error = scope_and_options.delete(:raise_error)
          two_factor = scope_and_options.delete(:two_factor)
          two_factor = false unless MonsoonOpenstackAuth.configuration.two_factor_enabled?

          session_store = session_store(controller)
          session = AuthSession.new(controller,session_store, scope_and_options)

          if session.authenticated?
            if !two_factor or two_factor_cookie_valid?(controller)
              # return session if already authenticated and two factor is ok
              return session
            else
              # redirect to two factor login form
              controller.redirect_to controller.monsoon_openstack_auth.two_factor_path(after_login: session.after_login_url)
              return nil
            end
          else
            # not authenticated!
            # raise error if options contains the flag
            if raise_error
              raise MonsoonOpenstackAuth::Authentication::NotAuthorized
            else
              # try to redirect to login form
              login_url = session.redirect_to_login_form_url
              # redirect to login form or root path
              if login_url
                controller.redirect_to login_url, two_factor: two_factor
              else
                controller.redirect_to(controller.main_app.root_path, notice: 'User is not authenticated!')
              end
            end
            return nil
          end
        end

        # create user from form and authenticate
        def create_from_login_form(controller, username,password, options={})
          options ||= options
          domain_id = options[:domain_id]
          domain_name = options[:domain_name]

          scope = if (domain_id && !domain_id.empty?)
            { domain: domain_id }
          elsif (domain_name && !domain_name.empty?)
            { domain_name: domain_name }
          else
            nil
          end

          session_store = session_store(controller)
          session = AuthSession.new(controller, session_store(controller), scope)
          session.login_form_user(username,password)
          session
        end

        def check_two_factor(controller,username,passcode)
          if MonsoonOpenstackAuth.configuration.two_factor_authentication_method.call(username,passcode)
            set_two_factor_cookie(controller)
            return true
          else
            return false
          end
        end

        # clear session_store if request session is presented
        def logout(controller)
          session_store = session_store(controller)
           if session_store
             session_store.delete_token
           end
        end

        def session_id_presented?(controller)
          not controller.request.session_options[:id].blank?
        end

        def session_store(controller)
          # return nil if request session id isn't provided
          return nil if controller.request.session_options[:id].blank?
          # return session store
          SessionStore.new(controller.session)
        end

        # check if cookie for two factor authentication is valid
        def two_factor_cookie_valid?(controller)
          return false unless controller.request.cookies[TWO_FACTOR_AUTHENTICATION]
          crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
          value = crypt.decrypt_and_verify(controller.request.cookies[TWO_FACTOR_AUTHENTICATION]) rescue nil
          return value=='valid'
        end

        # set cookie for two factor authentication
        def set_two_factor_cookie(controller)
          crypt = ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
          value = crypt.encrypt_and_sign('valid')
          controller.response.set_cookie(TWO_FACTOR_AUTHENTICATION, {value: value, expires: Time.now+1.day, path: '/'})
        end
      end

      def initialize(controller, session_store, scope={})
        @controller = controller
        @session_store = session_store
        @scope = scope

        # get api client
        @api_client = MonsoonOpenstackAuth.api_client
        @debug = MonsoonOpenstackAuth.configuration.debug?
      end

      def authenticated?
        return true if validate_session_token
        return true if validate_auth_token
        return true if validate_access_key
        return true if validate_sso_certificate
        return true if validate_http_basic
      end

      def rescope_token(requested_scope=@scope)
        if @session_store and @session_store.token_valid? and !@scope.empty?
          token = @session_store.token
          domain =  token[:domain]
          project = token[:project]

          if requested_scope[:project]
            return if project && project["id"]==requested_scope[:project]
            # scope= {project: {domain:{id: @scope[:domain]},id: @scope[:project]}}
            scope= if requested_scope[:domain]
              {project: {domain:{id: requested_scope[:domain]},id: requested_scope[:project]}}
            elsif requested_scope[:domain_name]
              {project: {domain:{name: requested_scope[:domain_name]},id: requested_scope[:project]}}
            end
          elsif requested_scope[:domain]
            return if domain && domain["id"]==requested_scope[:domain] && (project.nil? or project["id"].nil?)
            scope = {domain:{id:requested_scope[:domain]}}
          elsif requested_scope[:domain_name]
            return if domain && domain["name"]==requested_scope[:domain_name] && (project.nil? or project["id"].nil?)
            scope = {domain:{name:requested_scope[:domain_name]}}
          else

            # scope is empty -> no domain and project provided
            # return if token scope is also empty
            return if (domain.nil? and project.nil?)

            # did not return -> get new unscoped token
            scope="unscoped"
          end

          begin
            MonsoonOpenstackAuth.logger.info "rescope token." if @debug
            # scope has changed -> get new scoped token
            token = @api_client.authenticate_with_token(token[:value], scope)
            create_user_from_token(token)
            save_token_in_session_store(token)
          rescue => e
            if scope=="unscoped"
              scope=nil
              retry
            else
              raise MonsoonOpenstackAuth::Authentication::NotAuthorized.new("User has no access to the requested scope: #{e}")
            end
          end
        end
      end

      def validate_auth_token
        # return false if not allowed.
        unless MonsoonOpenstackAuth.configuration.token_auth_allowed?
          MonsoonOpenstackAuth.logger.info "validate_auth_token -> not allowed." if @debug
          return false
        end

        # didn't return -> token auth is allowed!
        auth_token = @controller.request.headers['HTTP_X_AUTH_TOKEN']

        unless auth_token
          MonsoonOpenstackAuth.logger.info "validate_auth_token -> auth token not presented." if @debug
          return false
        end

        # didn't return -> auth token is presented
        if @session_store and @session_store.token_valid? and @session_store.token_eql?(auth_token)
          # session token is valid and equal to the auth token
          # create user from session store
          create_user_from_session_store

          if logged_in?
            MonsoonOpenstackAuth.logger.info "validate_auth_token -> successful (session token is equal to auth token)." if @debug
            return true
          end
        end

        # didn't return -> validate auth token
        begin
          token = @api_client.validate_token(auth_token)
          if token
            # token is valid -> create user from token and save token in session store
            create_user_from_token(token)
            save_token_in_session_store(token)

            if logged_in?
              MonsoonOpenstackAuth.logger.info("validate_auth_token -> successful (username=#{@user.name}).") if @debug
              return true
            end
          end
          #rescue Excon::Errors::Unauthorized, Fog::Identity::OpenStack::NotFound => e
          #MonsoonOpenstackAuth.logger.error "token validation failed #{e}."
          #end
        rescue => e
          class_name = e.class.name
          if class_name.start_with?('Excon') or class_name.start_with?('Fog')
            MonsoonOpenstackAuth.logger.error "token validation failed #{e}."
          else
            MonsoonOpenstackAuth.logger.error "unknown error #{e}."
            raise e
          end
        end


        MonsoonOpenstackAuth.logger.info "validate_auth_token -> failed." if @debug
        return false
      end

      def validate_http_basic
        # return false if not allowed.
        unless MonsoonOpenstackAuth.configuration.basic_auth_allowed?
          MonsoonOpenstackAuth.logger.info "validate_http_basic -> not allowed." if @debug
          return false
        end

        # basic auth is allowed
        begin
          basic_auth_presented=false
          user = nil
          @controller.authenticate_with_http_basic do |username, password|
            # basic auth is presented
            basic_auth_presented=true
            MonsoonOpenstackAuth.logger.info "validate_http_basic -> username=#{username}." if @debug
            token = @api_client.authenticate_with_credentials(username,password)
            create_user_from_token(token)
            save_token_in_session_store(token)
          end

          unless basic_auth_presented
            MonsoonOpenstackAuth.logger.info "validate_http_basic -> basic auth header not presented." if @debug
            return false
          end

          if logged_in?
            MonsoonOpenstackAuth.logger.info "validate_http_basic -> successful (username=#{@user.name})." if @debug
            return true
          end
        rescue => e
          MonsoonOpenstackAuth.logger.error "basic auth failed: #{e}."
        end
        # basic auth authentication failed
        MonsoonOpenstackAuth.logger.info "validate_http_basic -> failed." if @debug
        return false
      end

      def validate_sso_certificate
        # return false if not allowed.
        unless MonsoonOpenstackAuth.configuration.sso_auth_allowed?
          MonsoonOpenstackAuth.logger.info "validate_sso_certificate -> not allowed." if @debug
          return false
        end

        # return false if invalid sso certificate.
        unless @controller.request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
          MonsoonOpenstackAuth.logger.info "validate_sso_certificate -> certificate not presented." if @debug
          return false
        end

        # sso user is presented
        # get username from certificate
        username = @controller.request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=([^,]*)')[1]

        # return false if no username given.
        if username.nil? or username.empty?
          MonsoonOpenstackAuth.logger.info "validate_sso_certificate -> user not presented." if @debug
          return false
        end

        scope = nil

        if MonsoonOpenstackAuth.configuration.provide_sso_domain
          begin
            domain_name_math = @controller.request.env['HTTP_SSL_CLIENT_S_DN'].match('O=([^\/]*)')
            domain_name = domain_name_math[1] if domain_name_math
            domain_name = "sap_default" if (domain_name && domain_name=~/SAP-AG/i)
            scope = { domain_name: domain_name }
          rescue => e
            MonsoonOpenstackAuth.logger.error "Could not find Domain for name=#{domain_name}. #{e}"
          end
        end

        # authenticate user as external user
        begin
          token = @api_client.authenticate_external_user(username,scope)
          # create user from token and save token in session store
          create_user_from_token(token)
          save_token_in_session_store(token)
        rescue => e
          MonsoonOpenstackAuth.logger.error "external user authentication failed #{e}."
        end

        if logged_in?
          MonsoonOpenstackAuth.logger.info "validate_sso_certificate -> successful (username=#{@user.name})." if @debug
          return true
        end

        MonsoonOpenstackAuth.logger.info "validate_sso_certificate -> failed." if @debug
        return false
      end

      def validate_session_token
        unless @session_store
          MonsoonOpenstackAuth.logger.info "validate_session_token -> session store not presented." if @debug
          return false
        end

        if @session_store.token_valid?
          # check if token is almost expired

          create_user_from_session_store
          if logged_in?
            MonsoonOpenstackAuth.logger.info "validate_session_token -> successful (username=#{@user.name})." if @debug
            return true
          end
        end

        MonsoonOpenstackAuth.logger.info "validate_session_token -> failed." if @debug
        return false
      end

      def validate_access_key
        unless MonsoonOpenstackAuth.configuration.access_key_auth_allowed?
          MonsoonOpenstackAuth.logger.info "validate_access_key -> not allowed." if @debug
          return false
        end

        user = nil

        access_key = params[:access_key] || params[:rails_auth_token]
        if(access_key)
          token = @api_client.authenticate_with_access_key(access_key)
          return false unless token
          create_user_from_token(token)
          save_token_in_session_store(token)

          if logged_in?
            MonsoonOpenstackAuth.logger.info "validate_access_key -> successful (username=#{@user.name})." if @debug
            return true
          end

        end
        return false
      end


      def save_token_in_session_store(token)
        if @session_store
          @session_store.token=token
        end
      end

      def create_user_from_session_store
        @user = MonsoonOpenstackAuth::Authentication::AuthUser.new(@session_store.token)
      end

      def create_user_from_token(token)
        @user = MonsoonOpenstackAuth::Authentication::AuthUser.new(token)
      end

      def user
        @user
      end

      def logged_in?
        not user.nil?
      end

      ############ LOGIN FORM FUCNTIONALITY ##################
      def login_form_user(username,password)
        unless @session_store
          MonsoonOpenstackAuth.logger.info "login_form_user -> session store not presented." if @debug
          return nil
        end

        begin
          # create auth token
          token = @api_client.authenticate_with_credentials(username, password, @scope)
          # save token in session
          save_token_in_session_store(token)
          # create auth user from token
          create_user_from_token(token)
          # success -> return true
          return true
        rescue => e
          MonsoonOpenstackAuth.logger.error "login_form_user -> failed. #{e}"
          MonsoonOpenstackAuth.logger.error e.backtrace.join("\n") if @debug
          # error -> return false
          return false
        end
      end

      def after_login_url
        MonsoonOpenstackAuth.configuration.login_redirect_url || @controller.params[:after_login] || @controller.request.env['REQUEST_URI']
      end

      def redirect_to_login_form_url
        return nil unless MonsoonOpenstackAuth.configuration.form_auth_allowed?

        if @scope[:domain_name]
          @controller.monsoon_openstack_auth.login_path(domain_name: @scope[:domain_name], after_login: after_login_url)
        else
          @controller.monsoon_openstack_auth.new_session_path(domain_id: @scope[:domain], after_login: after_login_url)
        end
      end

      def params
        @controller.params
      end

    end
  end
end
