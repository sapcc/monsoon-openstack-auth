module MonsoonOpenstackAuth
  class Configuration
    METHODS = [:api_endpoint, :api_userid, :api_password, :token_auth_allowed, :basic_atuh_allowed, 
      :sso_auth_allowed, :form_auth_allowed, :login_redirect_url, :debug]
    attr_accessor *METHODS

    def initialize
      @token_auth_allowed = true
      @basic_atuh_allowed = true
      @sso_auth_allowed   = true
      @form_auth_allowed  = true
      @debug = false
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
    
    def token_auth_allowed?; @token_auth_allowed; end
    def basic_atuh_allowed?; @basic_atuh_allowed; end
    def sso_auth_allowed?; @sso_auth_allowed; end
    def form_auth_allowed?; @form_auth_allowed; end
    def debug?; @debug; end
  end
end