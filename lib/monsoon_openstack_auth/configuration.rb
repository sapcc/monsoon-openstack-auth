module MonsoonOpenstackAuth  
  class Configuration    
    METHODS = [
      :connection_driver, :token_auth_allowed, :basic_auth_allowed,:access_key_auth_allowed, :sso_auth_allowed,
      :form_auth_allowed, :login_redirect_url, :debug, :logger, :authorization, :default_domain_name, :default_region
    ]
    
    attr_accessor *METHODS

    def initialize
      @default_region           = 'europe'
      @default_domain_name      = 'sap_default'
      @connection_driver        = MonsoonOpenstackAuth::ConnectionDriver::Default
      @token_auth_allowed       = true
      @basic_auth_allowed       = true
      @sso_auth_allowed         = true
      @form_auth_allowed        = true
      @access_key_auth_allowed  = false
      @debug                    = false
      @logger                   = MonsoonOpenstackAuth::LoggerWrapper.new(Rails ? Rails.logger : Logger.new(STDERR))
      @authorization            = AuthorizationConfig.new
    end
    
    # support old configuration format
    delegate :api_endpoint, to: :@connection_driver
    delegate :api_userid,   to: :@connection_driver
    delegate :api_password, to: :@connection_driver 
    # end

    def to_hash
      METHODS.inject({}){|hash,method_name| hash[method_name]=self.send(method_name); hash}
    end
    
    def to_s
      to_hash.to_s
    end
    
    def token_auth_allowed?; @token_auth_allowed; end
    def basic_auth_allowed?; @basic_auth_allowed; end
    def access_key_auth_allowed?; @access_key_auth_allowed; end
    def sso_auth_allowed?; @sso_auth_allowed; end
    def form_auth_allowed?; @form_auth_allowed; end
    def debug?; @debug; end
  end
  
  class AuthorizationConfig
    METHODS = [:policy_file_path, :controller_action_map, :context, :security_violation_handler]
    attr_accessor *METHODS
    
    def initialize
      @controller_action_map = {
          :index   => 'read',
          :show    => 'read',
          :new     => 'create',
          :create  => 'create',
          :edit    => 'update',
          :update  => 'update',
          :destroy => 'delete'
      }
      @context = Rails.application.class.parent_name if Rails
      @security_violation_handler = :authorization_forbidden
      @policy_file_path = 'config/policy.json'
    end
  end
end