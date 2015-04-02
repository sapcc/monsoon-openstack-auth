module MonsoonOpenstackAuth
  class DriverInterface
    def initialize(region)
      raise MonsoonOpenstackAuth::InvalidRegion.new("region not provided!") unless region
    end
    
    # returns a token as hash
    def validate_token(auth_token)
      raise MonsoonOpenstackAuth::InterfaceNotImplementedError.new("validate_token is not implemented yet!")
    end
  
    # returns a token as hash
    def authenticate_with_credentials(username,password, scope=nil)
      raise MonsoonOpenstackAuth::InterfaceNotImplementedError.new("authenticate_with_credentials is not implemented yet!")
    end

    # returns a token as hash
    def authenticate_with_token(token, scope=nil)
      raise MonsoonOpenstackAuth::InterfaceNotImplementedError.new("authenticate_with_token is not implemented yet!")
    end

    # returns a token as hash
    def authenticate_external_user(username, scope=nil)
      raise MonsoonOpenstackAuth::InterfaceNotImplementedError.new("authenticate_external_user is not implemented yet!")
    end
  end
end