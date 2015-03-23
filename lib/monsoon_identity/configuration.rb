module MonsoonIdentity
  class Configuration
    METHODS = [:api_endpoint, :api_userid, :api_password, :token_auth_allowed, :basic_atuh_allowed, :sso_auth_allowed, :form_auth_allowed]
    attr_accessor *METHODS
      
    # API_AUTH_ENDPOINT = 'http://localhost:8183/v3/auth/tokens'
    # API_USER_ID       = 'u-admin'
    # API_PASSWORD      = 'secret'

    def initialize
      @token_auth_allowed = true
      @basic_atuh_allowed = true
      @sso_auth_allowed   = true
      @form_auth_allowed  = true
    end
  
    def check
      raise ConfigurationError.new("Api credentials not provided") unless (api_endpoint and api_userid and api_password)
    end
    
    def to_hash
      METHODS.inject({}){|hash,method_name| hash[method_name]=self.send(method_name); hash}
    end
    
    def to_s
      to_hash.to_s
    end
  end
end