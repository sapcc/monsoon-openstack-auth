require "excon"

module MonsoonOpenstackAuth
  module ConnectionDriver
    class Default < MonsoonOpenstackAuth::ConnectionDriver::Interface
      class << self
        attr_accessor :api_endpoint, :ssl_verify_peer, :ssl_ca_path, :ssl_ca_file
      
        def connection_options
          result = { ssl_verify_peer: (ssl_verify_peer.nil? ? true : ssl_verify_peer) }
          result[:ssl_ca_file] = ssl_ca_file unless ssl_ca_file.nil?
          result[:ssl_ca_path] = ssl_ca_path unless ssl_ca_path.nil?  
          result[:debug] = MonsoonOpenstackAuth.configuration.debug
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
        
        def auth_params
          if api_userid or api_password

            auth_params = { 
              auth: { 
                identity: { 
                  methods: ["password"],
                  password: {
                    user: { 
                      id: api_userid,
                      password: api_password
                    }
                  }
                }
              }
            }
          
            if api_domain
              user_credentials = auth_params[:auth][:identity][:password][:user]
              user_credentials[:name] = user_credentials.delete(:id)
              user_credentials[:domain] = {name: api_domain}
            end
            auth_params
          end
        end
      end
    
      def initialize
        unless self.class.api_endpoint
          raise MonsoonOpenstackAuth::ConnectionDriver::ConfigurationError.new("No API endpoint provided!")
        end

        @connection = ::Excon.new(self.class.endpoint,self.class.connection_options)
      end  

      def authenticate(auth_params)

        MonsoonOpenstackAuth.logger.info "MonsoonOpenstackAuth#authenticate, #{auth_params.to_s}" if MonsoonOpenstackAuth.configuration.debug
        begin
          result = @connection.post( body: auth_params.to_json, headers: {"Content-Type" => "application/json"}) 
          
          body = JSON.parse(result.body)
          raise MonsoonOpenstackAuth::ConnectionDriver::AuthenticationError.new(body.to_s) unless body['token']

          token = body['token']
          token["value"] = result.headers["X-Subject-Token"]
          HashWithIndifferentAccess.new(token)
        rescue =>e
          MonsoonOpenstackAuth.logger.error e.to_s
          nil
        end
      end
      
      def validate_token(auth_token)
        cache.fetch key:auth_token,scope:nil do
          begin
            headers = {
              "Content-Type" => "application/json",
              "X-Auth-Token" => auth_token,
              "X-Subject-Token" => auth_token
            }
            
            result = @connection.get( headers: headers) 
            token = JSON.parse(result.body)['token']
            token["value"] = result.headers["X-Subject-Token"]
            HashWithIndifferentAccess.new(token)
          rescue =>e
            MonsoonOpenstackAuth.logger.error e.to_s
            nil
          end
        end
      end
        
      def authenticate_with_credentials(username,password, user_domain_params=nil)
        # build auth hash
        auth = { auth: { identity: { methods: ["password"], password:{} } } }
        
        # Do not set scope. User may not registered yet and so no member of the domain.
        # Using scope will fail the authentication for new users. 
        # build domain params. Authenticate user in given domain.
        if user_domain_params # scope is given
          domain_params = if user_domain_params[:domain]
            { domain: { id: user_domain_params[:domain] } }
          elsif user_domain_params[:domain_name]
            { domain: { name: user_domain_params[:domain_name] } }
          else
            {}
          end
          # try to authenticate with user name and password for given scope
          auth[:auth][:identity][:password] = { user:{ name: username,password: password }.merge(domain_params) }
        else # scope is nil
          # try to authenticate with user id and password
          auth[:auth][:identity][:password] = { user:{ id: username,password: password } }
        end   

        auth[:auth][:scope] = domain_params if user_domain_params and user_domain_params[:scoped_token]  
     
        authenticate(auth)
      end

      def authenticate_with_token(token, scope=nil)
        auth = {auth:{identity: {methods: ["token"],token:{ id: token}}}}
        auth[:auth][:scope]=scope if scope
        
        MonsoonOpenstackAuth.logger.info "authenticate_with_token -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        authenticate(auth)
      end

      def authenticate_external_user(username, user_domain_params={})
        #TODO: authenticate external user
        #REMOTE_USER=d000000
        #REMOTE_DOMAIN=test
        
        domain_params = if user_domain_params[:domain]
          { domain: { id: user_domain_params[:domain] } }
        elsif user_domain_params[:domain_name]
          { domain: { name: user_domain_params[:domain_name] } }
        else
          {}
        end
        
        auth = { auth: { identity: {methods: ["external"], external:{user: username }.merge(domain_params) }}}    

        MonsoonOpenstackAuth.logger.info "authenticate_external_user -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        authenticate(auth)
      end

      def authenticate_with_access_key(access_key, scope=nil)
        auth = {auth:{identity: {methods: ["access-key"],access_key:{key:access_key}}}}
        auth[:auth][:scope]=scope if scope
        MonsoonOpenstackAuth.logger.info "authenticate_with_access_key -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        
        authenticate(auth)
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
