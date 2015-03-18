module MonsoonIdentity
  class Auth
    def initialize(region,options={})
      p ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>AUTHENTICATE"
      p ">>>>>>>>>>>>>>>>>>>>>>REGION: #{region}"
      p ">>>>>>>>>>>>>>>>>>>>>>ORGANIZATION: #{options[:organization]}"
      p ">>>>>>>>>>>>>>>>>>>>>>PROJECT: #{options[:project]}"
    end
    
    def user
      OpenStruct.new(name: 'TestUser')
    end
  end
end