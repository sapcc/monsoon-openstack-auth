module MonsoonOpenstackAuth
  class Configuration
    METHODS = [
      :connection_driver, :token_auth_allowed, :basic_auth_allowed,:access_key_auth_allowed, :sso_auth_allowed, :provide_sso_domain,
      :form_auth_allowed, :login_redirect_url, :debug, :debug_api_calls, :logger, :authorization, :token_cache, :two_factor_authentication_method
    ]

    attr_accessor *METHODS

    def initialize
      @connection_driver        = MonsoonOpenstackAuth::ConnectionDriver::Default
      @token_auth_allowed       = true
      @basic_auth_allowed       = true
      @sso_auth_allowed         = true
      @form_auth_allowed        = true
      @access_key_auth_allowed  = false
      @two_factor_authentication_method = -> username,passcode { raise 'No two_factor_authentication_method given! Please provide a method for two factor authentication (config.two_factor_authentication_method=Proc).' }

      @provide_sso_domain       = true
      @debug                    = false
      @debug_api_calls          = false
      @logger                   = MonsoonOpenstackAuth::LoggerWrapper.new(Rails ? Rails.logger : Logger.new(STDERR))
      @authorization            = AuthorizationConfig.new
      @token_cache              = MonsoonOpenstackAuth::Cache::NoopCache
    end

    # support old configuration format
    delegate :api_endpoint, to: :@connection_driver
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
    METHODS = [:policy_file_path, :controller_action_map, :context, :security_violation_handler, :user_method, :reload_policy, :trace_enabled]
    attr_accessor *METHODS

    def initialize
      @controller_action_map = {}

      @context = Rails.application.class.parent_name if Rails
      @security_violation_handler = :authorization_forbidden
      @user_method = :current_user

      @policy_file_path = ['config/policy.json']
      @trace_enabled = false
      @reload_policy = false
    end
  end
end
