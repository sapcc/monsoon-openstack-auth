module MonsoonOpenstackAuth
  class Configuration    
    METHODS = [
      :connection_driver, :token_auth_allowed, :basic_atuh_allowed, :sso_auth_allowed, 
      :form_auth_allowed, :login_redirect_url, :debug
    ]
    
    attr_accessor *METHODS

    def initialize
      @connection_driver  = MonsoonOpenstackAuth::Driver::Default
      @token_auth_allowed = true
      @basic_atuh_allowed = true
      @sso_auth_allowed   = true
      @form_auth_allowed  = true
      @debug = false
    end
    
    # support old configuration format
    delegate :api_endpoint, to: :@connection_driver
    delegate :api_userid,   to: :@connection_driver
    delegate :api_password, to: :@connection_driver 
    # end
  
    def check
      raise UnknownConnectionDriver.new("Connection driver should be provided!") unless connection_driver
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