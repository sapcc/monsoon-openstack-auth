module MonsoonIdentity
  class Session
    attr_reader :session_store
    
    class << self
      
      # check if valid token, basic auth, sso or session token is presented      
      def check_authentication(controller, region, scope={})
        session = Session.new(controller,region,scope)
        session.authenticate_or_redirect
      end
      
      # create user from form and authenticate
      def create_from_login_form(controller,region,username,password,scope={})
        session = Session.new(controller, region, scope)
        redirect_to_url = session.login_form_user(username,password)
        return redirect_to_url
      end
      
      # clear session_store if request session is presented
      def logout(controller)
        if session_id_presented?(controller)
          session_store = MonsoonIdentity::SessionStore.new(controller.session)
          session_store.delete_token
        end
      end
      
      def session_id_presented?(controller)
        not controller.request.session_options[:id].blank?
      end
    end

    def initialize(controller, region, scope={})
      @controller = controller
      @region = region
      @scope = scope 
      
      # create new session store object
      @session_store = MonsoonIdentity::SessionStore.new(@controller.session) if self.class.session_id_presented?(controller)
      # get api client
      @api_client = MonsoonIdentity.api_client(@region) if @region
      
      @debug = MonsoonIdentity.configuration.debug?
    end
    
    def authenticate_or_redirect
      if authenticated?
        get_scoped_token if @session_store and !@scope.empty?
        return self
      elsif MonsoonIdentity.configuration.form_auth_allowed? and @session_store
        redirect_to_login_form and return
      else
        @controller.redirect_to @controller.main_app.root_path, notice: 'User is not authenticated!'      
      end
    end
    
    def authenticated?
      return true if validate_session_token
      return true if validate_auth_token
      return true if validate_sso_certificate
      return true if validate_http_basic
    end
    
    def get_scoped_token
      if @session_store and @session_store.token_valid? 
        token = @session_store.token
        domain =  token[:domain] 
        project = token[:project]

        if @scope[:project]
          return if project && project["id"]==@scope[:project]
          scope= {project: {domain:{id: @scope[:organization]},id: @scope[:project]}}
        elsif @scope[:organization]
          return if domain && domain["id"]==@scope[:organization]
          scope = {domain:{id:@scope[:organization]}}
        else
          #TODO: verify if scope=nil should reset the token to unscoped token
          # unless token&&(domain || project)
          # #if !token || (!domain && !project)
          #   return
          # end
          # scope=nil
          return
        end
        
        begin
          # scope has changed -> get new scoped token
          token = @api_client.authenticate_with_token(token[:value], scope) 
          create_user_from_token(token)
          save_token_in_session_store(token)
        rescue => e
          raise MonsoonIdentity::NotAuthorized.new("User has no access to the requested organization")
        end
      end
    end
   

    
    def validate_auth_token
      unless MonsoonIdentity.configuration.token_auth_allowed?   
        Rails.logger.info "Monsoon Identity: validate_auth_token -> not allowed." if @debug
        return false   
      end

      auth_token = @controller.request.headers['HTTP_X_AUTH_TOKEN']
      
      unless auth_token
        Rails.logger.info "Monsoon Identity: validate_auth_token -> auth token not presented." if @debug
        return false
      end
       
      if auth_token and MonsoonIdentity.configuration.token_auth_allowed?
        # auth token is presented
        if @session_store and @session_store.token_valid? and @session_store.token_eql?(auth_token)
          # session token is valid and equal to the auth token
          # create user from session store
          create_user_from_session
          
          if logged_in?
            Rails.logger.info "Monsoon Identity: validate_auth_token -> successful (session token is equal to auth token)." if @debug
            return true
          end
        end
        
        # didn't returned -> validate auth token
        begin
          token = @api_client.validate_token(auth_token) #self.class.keystone_connection(@region).tokens.validate(auth_token)
          if token
            # token is valid -> create user from token and save token in session store
            create_user_from_token(token)
            save_token_in_session_store(token)
            
            if logged_in?
              Rails.logger.info("Monsoon Identity: validate_auth_token -> successful (username=#{@user.name}).") if @debug
              return true
            end
          end
        rescue Fog::Identity::OpenStack::NotFound
          Rails.logger.error "Monsoon Identity: token validation failed #{e}."
        end  
      end

      Rails.logger.info "Monsoon Identity: validate_auth_token -> failed." if @debug
      return false      
    end
    
    def validate_http_basic
      # return false if not allowed.
      unless MonsoonIdentity.configuration.basic_atuh_allowed?
        Rails.logger.info "Monsoon Identity: validate_http_basic -> not allowed." if @debug
        return false
      end

      # basic auth is allowed
      begin
        basic_auth_presented=false
        user = nil
        @controller.authenticate_with_http_basic do |username, password|
          # basic auth is presented
          basic_auth_presented=true
          Rails.logger.info "Monsoon Identity: validate_http_basic -> username=#{username}." if @debug
          token = @api_client.authenticate_with_credentials(username,password)
          create_user_from_token(token)
          save_token_in_session_store(token)
        end
        
        unless basic_auth_presented
          Rails.logger.info "Monsoon Identity: validate_http_basic -> basic auth header not presented." if @debug
          return false
        end
        
        if logged_in?
          Rails.logger.info "Monsoon Identity: validate_http_basic -> successful (username=#{@user.name})." if @debug
          return true
        end
      rescue => e
        Rails.logger.error "Monsoon Identity: basic auth failed: #{e}."
      end
      # basic auth authentication failed
      Rails.logger.info "Monsoon Identity: validate_http_basic -> failed." if @debug
      return false
    end
    
    def validate_sso_certificate
      # return false if not allowed.
      unless MonsoonIdentity.configuration.sso_auth_allowed? 
        Rails.logger.info "Monsoon Identity: validate_sso_certificate -> not allowed." if @debug
        return false
      end
      
      # return false if invalid sso certificate. 
      unless @controller.request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
        Rails.logger.info "Monsoon Identity: validate_sso_certificate -> certificate not presented." if @debug
        return false
      end

      # sso user is presented
      # get username from certificate
      username = @controller.request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=([^,]*)')[1]
      
      # return false if no username given.
      if username.nil? or username.empty?
        Rails.logger.info "Monsoon Identity: validate_sso_certificate -> user not presented." if @debug
        return false
      end
      
      # authenticate user as external user 
      begin
        token = @api_client.authenticate_external_user(username)
        # create user from token and save token in session store
        create_user_from_token(token)
        save_token_in_session_store(token)
      rescue => e
        Rails.logger.error "Monsoon Identity: external user authentication failed #{e}."
      end

      if logged_in?
        Rails.logger.info "Monsoon Identity: validate_sso_certificate -> successful (username=#{@user.name})." if @debug
        return true
      end

      Rails.logger.info "Monsoon Identity: validate_sso_certificate -> failed." if @debug
      return false
    end
    
    def validate_session_token
      unless @session_store
        Rails.logger.info "Monsoon Identity: validate_session_token -> session store not presented." if @debug
        return false  
      end
      
      if @session_store.token_valid?
        create_user_from_session_store
        if logged_in?
          Rails.logger.info "Monsoon Identity: validate_session_token -> successful (username=#{@user.name})." if @debug
          return true
        end
      end
      Rails.logger.info "Monsoon Identity: validate_session_token -> failed." if @debug
      return false
    end

    def save_token_in_session_store(token)
      @session_store.token=token if @session_store  
    end
    
    def create_user_from_session_store
      @user = MonsoonIdentity::User.new(@session_store.token)
    end
    
    def create_user_from_token(token)
      @user = MonsoonIdentity::User.new(token) 
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
        Rails.logger.info "Monsoon Identity: login_form_user -> session store not presented." if @debug
        return nil
      end
      
      begin          
        redirect_to_url = (@session_store.redirect_to || @controller.main_app.root_path)
        token = @api_client.authenticate_with_credentials(username, password)
        @session_store.token=token 
        @session_store.delete_redirect_to
        create_user_from_token(token)
        return redirect_to_url
      rescue => e
        Rails.logger.error "Monsoon Identity: login_form_user -> failed. #{e}"
        return nil
      end
    end
    
    def redirect_to_login_form
      @session_store.redirect_to = @controller.request.env['REQUEST_URI'] if @session_store
      @controller.redirect_to @controller.monsoon_identity.new_session_path(@region)
    end
    
  end
end