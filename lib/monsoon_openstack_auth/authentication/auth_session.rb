module MonsoonOpenstackAuth
  module Authentication
    class AuthSession
      @@redirect_to_callbacks_mutex = Mutex.new
      
      attr_reader :session_store
      attr_accessor :redirect_to_callback
           
      class << self        
          
        # This methods saves callback urls in a static hash. 
        # In this way, it is possible to access the callbacks across different controllers.
        # See it in action in authentication.rb:38   
        def add_redirect_to_callback(url)
          return nil unless url
          @@redirect_to_callbacks_mutex.synchronize do
            @redirect_to_callbacks ||= {}
            new_id = @redirect_to_callbacks.keys.length + 1
            @redirect_to_callbacks[new_id] = url
            return new_id
          end
        end
    
        def get_redirect_to_callback(id)
          return nil unless @redirect_to_callbacks
          return nil unless id
          @redirect_to_callbacks[id]
        end
        
        
        def load_user_from_session(controller)
          session = AuthSession.new(controller,session_store(controller), nil)
          session.validate_session_token
          return session
        end
        
        # check if valid token, basic auth, sso or session token is presented
        def check_authentication(controller, scope_and_options={})
          raise_error = scope_and_options.delete(:raise_error)

          session_store = session_store(controller)
          # save redirect_to callback id
          session_store.redirect_to_callback_id=(scope_and_options.delete(:redirect_to_callback_id))
          
          session = AuthSession.new(controller,session_store, scope_and_options)
          
          # return session if already authenticated
          return session if session.authenticated?
          
          # not authenticated!
          # raise error if options contains the flag
          if raise_error
            raise MonsoonOpenstackAuth::Authentication::NotAuthorized
          else
            # try to redirect to login form
            session.redirect_to_login_form or controller.redirect_to(controller.main_app.root_path, notice: 'User is not authenticated!')
          end
          return nil
        end
      
        # create user from form and authenticate
        def create_from_login_form(controller, username,password, domain_id=nil, domain_name=nil)          
          scope = if (domain_id && !domain_id.empty?)
            { domain: domain_id }
          elsif (domain_name && !domain_name.empty?)
            { domain_name: domain_name }
          else
            nil
          end

          session_store = session_store(controller)      
          session = AuthSession.new(controller, session_store(controller), scope)
          # get redirect_to_callback and save it in session
          # this callback is used in session to determine the redirect_url 
          session.redirect_to_callback=AuthSession.get_redirect_to_callback(session_store.redirect_to_callback_id)
          
          redirect_to_url = session.login_form_user(username,password)
          # delete redirect_to_callback_id from session if succesfully logged in.
          session_store.delete_redirect_to_callback_id unless redirect_to_url.nil?
          return redirect_to_url
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
          # renew token automatically
          if @session_store.token_almost_expired?
            # renew token
            begin
              auth_token = @session_store.token["value"]
              scope = @session_store.token["project"] || @session_store.token["domain"] 
              token = @api_client.authenticate_with_token(auth_token,scope)
              if token
                # token is valid -> create user from token and save token in session store
                create_user_from_token(token)
                save_token_in_session_store(token)
          
                if logged_in?
                  MonsoonOpenstackAuth.logger.info("reauthenticate using session token -> successful (username=#{@user.name}).") if @debug
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
          else
            create_user_from_session_store
            if logged_in?
              MonsoonOpenstackAuth.logger.info "validate_session_token -> successful (username=#{@user.name})." if @debug
              return true
            end
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
          redirect_to_url = (MonsoonOpenstackAuth.configuration.login_redirect_url || self.redirect_to_callback || @session_store.requested_url || @controller.main_app.root_path)
          token = @api_client.authenticate_with_credentials(username, password, @scope)

          save_token_in_session_store(token) 
          create_user_from_token(token)
                  
          # redirect_url is a Proc (defined in initializer)
          if redirect_to_url.is_a?(Proc)
            redirect_to_url = redirect_to_url.call(@user, @session_store.requested_url, @session_store.referer_url)
          end
          @session_store.delete_requested_url
          @session_store.delete_referer_url

          return redirect_to_url
        rescue => e
          MonsoonOpenstackAuth.logger.error "login_form_user -> failed. #{e}"
          MonsoonOpenstackAuth.logger.error e.backtrace.join("\n") if @debug
          return nil
        end
      end
    
      def redirect_to_login_form
        if MonsoonOpenstackAuth.configuration.form_auth_allowed? and @session_store
          
          if @session_store
            # save request und referer urls in session
            @session_store.requested_url= @controller.request.env['REQUEST_URI']
            @session_store.referer_url= @controller.request.referer
          end
          
          if @scope[:domain_name]
            @controller.redirect_to @controller.monsoon_openstack_auth.login_path(domain_name: @scope[:domain_name])
          else  
            @controller.redirect_to @controller.monsoon_openstack_auth.new_session_path(domain_id: @scope[:domain])
          end

          return true
        else
          return false
        end
      end

      def params
        @controller.params
      end
        
    end
  end
end
