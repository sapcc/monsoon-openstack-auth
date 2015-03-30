module MonsoonIdentity
  class ApiClient
    attr_reader :connection
    
    def initialize(region)
      @connection = Fog::IdentityV3::OpenStack.new({
        openstack_region:   region,
        openstack_auth_url: MonsoonIdentity.configuration.api_endpoint,
        openstack_userid:   MonsoonIdentity.configuration.api_userid,
        openstack_api_key:  MonsoonIdentity.configuration.api_password
      })
      self
    end
    
    def validate_token(auth_token)
      HashWithIndifferentAccess.new(@connection.tokens.validate(auth_token).attributes)
    end
    
    def authenticate_with_credentials(username,password, scope=nil)
      auth = {auth:{identity: {methods: ["password"],password:{user:{id: username,password: password}}}}}
      auth[:auth][:scope]=scope if scope
      #Rails.logger.info "Monsoon Identity: authenticate_with_credentials -> #{auth}" if MonsoonIdentity.configuration.debug
      HashWithIndifferentAccess.new(@connection.tokens.authenticate(auth).attributes)
    end

    def authenticate_with_token(token, scope=nil)
      auth = {auth:{identity: {methods: ["token"],token:{ id: token}}}}
      auth[:auth][:scope]=scope if scope
      Rails.logger.info "Monsoon Identity: authenticate_with_token -> #{auth}" if MonsoonIdentity.configuration.debug
      HashWithIndifferentAccess.new(@connection.tokens.authenticate(auth).attributes)
    end

    def authenticate_external_user(username, scope=nil)
      #TODO: authenticate external user
      #REMOTE_USER=d000000
      #REMOTE_DOMAIN=test

      auth = { auth: { identity: {methods: ["external"], external:{user: username }}}}
      auth[:auth][:scope]=scope if scope
      Rails.logger.info "Monsoon Identity: authenticate_external_user -> #{auth}" if MonsoonIdentity.configuration.debug
      HashWithIndifferentAccess.new(@connection.tokens.authenticate(auth).attributes)
    end
  end
end