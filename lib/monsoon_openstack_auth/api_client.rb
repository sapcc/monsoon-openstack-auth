module MonsoonOpenstackAuth
  class ApiClient
    attr_reader :connection_driver

    def initialize(region)
      @connection_driver = MonsoonOpenstackAuth.configuration.connection_driver.new(region)
    end
      
    delegate :validate_token,                 to: :@connection_driver
    delegate :authenticate_with_credentials,  to: :@connection_driver
    delegate :authenticate_with_token,        to: :@connection_driver
    delegate :authenticate_with_access_key,   to: :@connection_driver
    delegate :authenticate_external_user,     to: :@connection_driver
    delegate :default_domain,                 to: :@connection_driver
    delegate :create_user_domain_role,        to: :@connection_driver
    delegate :domain_by_name,                 to: :@connection_driver
  end
end