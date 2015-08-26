module MonsoonOpenstackAuth
  module ConnectionDriver
    class Default < MonsoonOpenstackAuth::ConnectionDriver::Interface
      class << self
        attr_accessor :api_endpoint, :api_userid, :api_password, :api_domain, :ssl_verify_peer, :ssl_ca_path, :ssl_ca_file
      
        def connection_options
          result = { ssl_verify_peer: (ssl_verify_peer.nil? ? true : ssl_verify_peer) }
          result[:ssl_ca_file] = ssl_ca_file unless ssl_ca_file.nil?
          result[:ssl_ca_path] = ssl_ca_path unless ssl_ca_path.nil?  
          result
        end
      
        def endpoint
          return @endpoint if @endpoint
          begin
            version = URI(api_endpoint).path.split('/')[1]
            @endpoint = URI.join(api_endpoint, "/#{version}/auth/tokens").to_s
          rescue => e
            Rails.logger.info("api_endpoint: #{api_endpoint}")
            raise MalformedApiEndpoint.new(e)
          end
        end
      end
    
      def initialize(region)
        # connect service user
        unless (self.class.api_endpoint or self.class.api_userid or self.class.api_password)
          raise MonsoonOpenstackAuth::ConnectionDriver::ConfigurationError.new("Api credentials not provided! Please provide 
            connection_driver.api_endpoint, connection_driver.api_userid and 
            connection_driver.api_password (in initializer).") 
        end    
      
        MonsoonOpenstackAuth.logger.info("Monsoon Openstack Auth -> api_endpoint: #{MonsoonOpenstackAuth::ConnectionDriver::Default.endpoint}")
        
        params = {
          openstack_auth_url: self.class.endpoint,
          openstack_region:   region,
          openstack_api_key:  self.class.api_password,
          connection_options: self.class.connection_options,
          openstack_service_type: ["identityv3"]
        }
        
        if self.class.api_domain
          # scoped service user -> use domain, username and password
          params[:openstack_domain_name] = self.class.api_domain
          params[:openstack_username] = self.class.api_userid
        else
          # unscoped service user -> use userid and password
          params[:openstack_userid] = self.class.api_userid
        end
        
        begin            
          @fog = Fog::IdentityV3::OpenStack.new(params)
        rescue => e
          raise MonsoonOpenstackAuth::ConnectionDriver::ConnectionError.new(e)
        end
        self
      end  
    
      def connection
        @fog
      end
      
      def domain_by_name(domain_name)
        @fog.domains.all(name:domain_name).first
      end
      
      # DEPRECATED
      # TODO: remove it in one month (end of august)  
      def create_user_domain_role(user_id,role_name)
        return false if user_id.nil? or role_name.nil?
        user = @fog.users.find_by_id(user_id)
        member_role = @fog.roles.all(name:role_name).first
        user.grant_role(member_role.id)
      end
      
      # Default Domain such a sap_default
      def default_domain(name=MonsoonOpenstackAuth.configuration.default_domain_name)
        unless @default_domain
          begin
            dd = @fog.domains.all(name: name).first
            return nil unless dd
            @default_domain = MonsoonOpenstackAuth::Authentication::AuthDefaultDomain.new(id: dd.id, name: dd.name, description: dd.description, enabled: dd.enabled)
          rescue => e
            raise MonsoonOpenstackAuth::ConnectionDriver::ConnectionError.new(e)
          end
        end
        return @default_domain
      end
    
      def validate_token(auth_token)
        cache.fetch key:auth_token,scope:nil do
          HashWithIndifferentAccess.new(@fog.tokens.validate(auth_token).attributes)
        end
      end
  
      def authenticate_with_credentials(username,password, scope=nil)
        # build auth hash
        auth = { auth: { identity: { methods: ["password"], password:{} } } }
        
        # build domain params. Authenticate user in given domain.
        if scope # scope is given
          domain_params = if scope[:domain]
            {domain: {id: scope[:domain]}}
          else
            nil
          end
          # try to authenticate with user name and password for given scope
          auth[:auth][:identity][:password] = { user:{ name: username,password: password }.merge(domain_params) }
        else # scope is nil
          # try to authenticate with user id and password
          auth[:auth][:identity][:password] = { user:{ id: username,password: password } }
        end   
        #MonsoonOpenstackAuth.logger.info "authenticate_with_credentials -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end

      def authenticate_with_token(token, scope=nil)
        auth = {auth:{identity: {methods: ["token"],token:{ id: token}}}}
        auth[:auth][:scope]=scope if scope
        
        MonsoonOpenstackAuth.logger.info "authenticate_with_token -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end

      def authenticate_external_user(username, scope=nil)
        #TODO: authenticate external user
        #REMOTE_USER=d000000
        #REMOTE_DOMAIN=test

        domain_params = if scope && scope[:domain]
          {domain: {id: scope[:domain]}}
        else
          {}
        end
        
        auth = { auth: { identity: {methods: ["external"], external:{user: username }.merge(domain_params) }}}    
            
        #auth[:auth][:scope]=scope if scope
        MonsoonOpenstackAuth.logger.info "authenticate_external_user -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end

      def authenticate_with_access_key(access_key, scope=nil)
        auth = {auth:{identity: {methods: ["access-key"],access_key:{key:access_key}}}}
        auth[:auth][:scope]=scope if scope
        MonsoonOpenstackAuth.logger.info "authenticate_with_access_key -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      rescue Excon::Errors::Unauthorized

      end
      
      protected

        def cache
          impl = MonsoonOpenstackAuth.configuration.token_cache
          impl.new
        end

    end
  end
end
