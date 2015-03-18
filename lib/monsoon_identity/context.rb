module MonsoonIdentity
  class Context
    attr_reader :user
    
    def initialize(user)
      @user = user
    end
  end
end