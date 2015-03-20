require 'monsoon_fog'

module MonsoonIdentity
  class Auth
    # TODO: move to config
    API_AUTH_ENDPOINT = 'http://localhost:8183/v3/auth/tokens'
    API_USER_ID       = 'u-admin'
    API_PASSWORD      = 'secret'
    
    # API_AUTH_ENDPOINT = 'http://localhost:5000/v3/auth/tokens'
    # API_USER_ID       = '8d5732a0ebd9485396351d74e24c9647'
    # API_PASSWORD      = 'openstack'
    # END

    class << self 
      # TODO: move to config
      def token_auth_allowed?; true; end
      def basic_atuh_allowed?; true; end
      def sso_auth_allowed?; true; end
      def form_auth_allowed?; true; end
      # END
       
      def authenticate(controller, region, scope={})
        Auth.new(controller, region, scope)
      end
      
      def keystone_connection(region)
        if @region and @region==region and @keystone_connection
          return @keystone_connection
        else
          @region = region
          @keystone_connection ||= Fog::IdentityV3::OpenStack.new({
            openstack_region: @region,
            openstack_api_key: API_PASSWORD,
            openstack_userid: API_USER_ID,
            openstack_auth_url: API_AUTH_ENDPOINT
          })
        end
      end       
      
      def keystone_password_auth(region, username,password, scope=nil)      
        auth = {auth:{identity: {methods: ["password"],password:{user:{id: username,password: password}}}, scope: scope}}
        HashWithIndifferentAccess.new(keystone_connection(region).tokens.authenticate(auth).attributes)
      end
      
      def keystone_token_auth(region, token, scope=nil)      
        auth = {auth:{identity: {methods: ["token"],token:{ id: token}}, scope: scope}}
        p auth
        HashWithIndifferentAccess.new(keystone_connection(region).tokens.authenticate(auth).attributes)
      end
      
      def keystone_external_auth(region, username, scope=nil)
        #REMOTE_USER=d000000
        #REMOTE_DOMAIN=test

        auth = { auth: { identity: {methods: ["external"], external:{user: username }}, scope: scope}}
        HashWithIndifferentAccess.new(keystone_connection(region).tokens.authenticate(auth).attributes)
      end
      
      def session_id_presented?(controller)
        not controller.request.session_options[:id].blank?
      end
      
      def login_form_user(controller,username,password,options={})
        begin
          session = MonsoonIdentity::Session.new(controller.session)
          redirect_to_url = session.redirect_to || controller.main_app.root_path
          region = session.region

          token = keystone_password_auth(region, username, password)
          session.token=token #if session_id_presented?

          session.delete_redirect_to
          session.delete_region
          return redirect_to_url
        rescue => e
          Rails.logger.info("Faild to login user #{e}")
          return false
        end
      end

      def logout_user(controller)
        session = MonsoonIdentity::Session.new(controller.session)
        session.delete_token
      end
      
      def user_from_session(controller)
        session = MonsoonIdentity::Session.new(controller.session)
        if session_id_presented?(controller) and session.token_presented?
          user = MonsoonIdentity::User.new(session.token) if session.token_valid?
          return user if user
        end
        return nil
      end

    end
    

    def initialize(controller, region, scope={})
      @controller = controller
      @region = region
      @scope = scope
      @session = MonsoonIdentity::Session.new(@controller.session)
      
      prepare_keystone_token

      if authenticated?
        return self
      elsif self.class.form_auth_allowed?
        redirect_to_login_form and return
      else
        @controller.redirect_to @controller.main_app.root_path, notice: 'User is not authenticated!'      
      end
    end
    
    def authenticated?
      return true if authenticate_with_session_token
      return true if authenticate_with_auth_token
      return true if authenticate_with_sso_certificate
      return true if authenticate_with_http_basic
    end
    
    def prepare_keystone_token
      if @session.token_valid? 
        token = @session.token
        domain =  token[:domain] 
        project = token[:project]
        p ">>>>>>>>>>>>>>>>>>>>>>project: #{@scope[:project]}"
        p ">>>>>>>>>>>>>>>>>>>>>>organization: #{@scope[:organization]}"
        p ">>>>>>>>>>>>>>>>>>>>>>token project: #{project}"
        p ">>>>>>>>>>>>>>>>>>>>>>token organization: #{domain}"
        
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
          #   p ">>>>>>>>>>>>>>>>>>return"
          #   return
          # end
          # p ">>>>>>>>>>>>>>>>>>>scope to nil"
          # scope=nil
          return
        end
        
        begin
          token = self.class.keystone_token_auth(@region, token[:value], scope) 
          load_user_from_token(token)
          @session.token=token if session_id_presented?    
        rescue
          raise MonsoonIdentity::NotAuthorized.new("User has no access to the requested organization")
        end
      end
   end
    
    def redirect_to_login_form
      @session.redirect_to = @controller.request.env['REQUEST_URI']
      @session.region = @region
      @controller.redirect_to @controller.monsoon_identity.new_session_path
    end
    
    def authenticate_with_auth_token
      auth_token = @controller.request.headers['HTTP_X_AUTH_TOKEN']
      
      if auth_token and self.class.token_auth_allowed?
        Rails.logger.info ">>>>>>>>>>>>> Auth Token presented"
        if session_id_presented? and @session.token_valid? and @session.token_eql?(auth_token)
          Rails.logger.info ">>>>>>>>>> Session Token valid"
          load_user_from_session
          Rails.logger.info(">>>>>>>>>>>> Authenticate From Session Token") if logged_in?
          return true if logged_in?
        end

        begin
          token = self.class.keystone_connection(@region).tokens.validate(auth_token)
          if token
            load_user_from_token(token)
            @session.token=token if session_id_presented?
            Rails.logger.info(">>>>>>>>>>>>>>>>> Auth Token Validation Successful") if logged_in?
            return true if logged_in?
          end
        rescue Fog::Identity::OpenStack::NotFound
          Rails.logger.info "Token authentication failed #{e}"
        end

        return false
      end
      
    end
    
    def authenticate_with_http_basic
      p ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BASIC AUTH"
      begin
        @controller.authenticate_with_http_basic do |username, password|
          Rails.logger.info ">>>>>>>>>>>>> Basic Auth Header is presented"
          Rails.logger.info ">>>>>>>>>>>>> username: #{username}, password: #{password}"
          token = self.class.keystone_password_auth(@region,username,password)
          load_user_from_token(token)
          @session.token=token if session_id_presented?
        end
        Rails.logger.info ">>>>>>>>>>>>> Basic Auth Successful" if logged_in?
        return true if logged_in?
      rescue
        p "Basic Auth ERROR"
      end
      return false
    end
    
    def authenticate_with_sso_certificate
      if self.class.sso_auth_allowed? and @controller.request.env['HTTP_SSL_CLIENT_VERIFY'] == 'SUCCESS'
        Rails.logger.info ">>>>>>>>>>>>> SSO Header is presented"
        username = request.env['HTTP_SSL_CLIENT_S_DN'].match('CN=([^,]*)')[1]
        unless username.nil? || username.empty?
          begin
            token = self.class.keystone_external_auth(@region,username)
            load_user_from_token(token)
            @session.token=token if session_id_presented?
          rescue
          end
        end
        Rails.logger.info ">>>>>>>>>>>>> SSO Auth Successful" if logged_in?
        return true if logged_in?
      end
      return false
    end
    
    def authenticate_with_session_token
      if session_id_presented? and @session.token_presented?
        load_user_from_session
        Rails.logger.info ">>>>>>>>>>>>> Authenticate From Session Token" if logged_in?
        return true if logged_in?
      end
      return false
    end

    
    def session_id_presented?
      self.class.session_id_presented?(@controller)
    end
    
    def load_user_from_session
      @user = MonsoonIdentity::User.new(@session.token) if @session.token_valid?
    end
    
    def load_user_from_token(token)
      @user = MonsoonIdentity::User.new(token) 
    end
    
    def user
      @user
    end
    
    def logged_in?
      not @user.nil?
    end
  end
end