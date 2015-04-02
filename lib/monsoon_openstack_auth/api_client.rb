module MonsoonOpenstackAuth
  class ApiClient
    attr_reader :connection_driver

    def initialize(region)
      @connection_driver = MonsoonOpenstackAuth.configuration.connection_driver.new(region)
      self
    end
    
    delegate :validate_token,                 to: :@connection_driver
    delegate :authenticate_with_credentials,  to: :@connection_driver
    delegate :authenticate_with_token,        to: :@connection_driver
    delegate :authenticate_external_user,     to: :@connection_driver
  end
end