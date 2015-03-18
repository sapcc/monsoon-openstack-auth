module MonsoonIdentity
  class TokenValue < Struct
    undef []=
  
    def initialize(*args, &block)    
      super(*args, &block)
      members.each{ |member| instance_eval{ undef :"#{member}=" } }
    end
  end
end