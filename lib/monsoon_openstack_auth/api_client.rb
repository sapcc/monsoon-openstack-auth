module MonsoonOpenstackAuth
  class ApiClient
    attr_reader :connection_driver

    def initialize(region)
      @connection_driver = MonsoonOpenstackAuth.configuration.connection_driver.new(region)
    end
    
    def service_user
      @connection_driver.connection
    end
      
    delegate :validate_token,                 to: :@connection_driver
    delegate :authenticate_with_credentials,  to: :@connection_driver
    delegate :authenticate_with_token,        to: :@connection_driver
    delegate :authenticate_with_access_key,   to: :@connection_driver
    delegate :authenticate_external_user,     to: :@connection_driver
    delegate :default_domain,                 to: :@connection_driver
    delegate :create_user_domain_role,        to: :@connection_driver
    delegate :domain_by_name,                 to: :@connection_driver
    delegate :user_details,                   to: :@connection_driver 
    
    def auth_user(username,password,user_domain_params={domain: nil, domain_name: nil, scoped_token: false})
      token = authenticate_with_credentials(username,password,user_domain_params)
      MonsoonOpenstackAuth::Authentication::AuthUser.new(@region, token) 
    end
  end
end