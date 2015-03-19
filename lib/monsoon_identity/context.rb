module MonsoonIdentity
  class Context
    attr_reader :user
    
    def initialize(user,token)
      @user = user
      @token = token
    end
    
    def token_value
      @token[:value]
    end
  end
end