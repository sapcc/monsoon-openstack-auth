module MonsoonOpenstackAuth
  module Authentication
    module Driver
      class Default < MonsoonOpenstackAuth::Authentication::DriverInterface
        class << self
          attr_accessor :api_endpoint, :api_userid, :api_password, :ssl_verify_peer, :ssl_ca_path, :ssl_ca_file
        
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
              raise MalformedApiEndpoint.new(e)
            end
          end
        end
      
        def initialize(region)
          if self.class.api_endpoint.nil? and self.class.api_userid.nil? and self.class.api_password.nil?
            raise ConfigurationError.new("Api credentials not provided! Please provide 
              connection_driver.api_endpoint, connection_driver.api_userid and 
              connection_driver.api_password (in initializer).") 
          end    
        
          MonsoonOpenstackAuth.logger.info("Monsoon Openstack Auth -> api_endpoint: #{MonsoonOpenstackAuth::Authentication::Driver::Default.endpoint}")
          @fog = Fog::IdentityV3::OpenStack.new({
            openstack_region:   region,
            openstack_auth_url: MonsoonOpenstackAuth::Authentication::Driver::Default.endpoint,
            openstack_userid:   MonsoonOpenstackAuth::Authentication::Driver::Default.api_userid,
            openstack_api_key:  MonsoonOpenstackAuth::Authentication::Driver::Default.api_password,
            connection_options: MonsoonOpenstackAuth::Authentication::Driver::Default.connection_options
          })
          self
        end  
      
        def connection
          @fog
        end
      
        def validate_token(auth_token)
          HashWithIndifferentAccess.new(@fog.tokens.validate(auth_token).attributes)
        end
    
        def authenticate_with_credentials(username,password, scope=nil)
          auth = {auth:{identity: {methods: ["password"],password:{user:{id: username,password: password}}}}}
          auth[:auth][:scope]=scope if scope
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

          auth = { auth: { identity: {methods: ["external"], external:{user: username }}}}
          auth[:auth][:scope]=scope if scope
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
      end
    end
  end
end