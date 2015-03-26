module MonsoonIdentity
  class User
    attr_reader :context#, :token, :id, :name, :user_domain_id, :domain_id, :domain_name, :project_id, :project_name, 
      #:service_catalog, :roles, :endpoint, :projects, :region
    
    def initialize(token_hash)
      raise MonsoonIdentity::MalformedToken.new("Token is nil.") if token_hash.nil?
      raise MonsoonIdentity::MalformedToken.new("Token should be a hash.") unless token_hash.is_a?(Hash)
      
      @context = token_hash
      #init_from_token(token_hash)
    end

    
    def enabled?
      @enabled
    end
    
    def token
      @token ||= @context["value"] 
    end
    
    def id
      @id ||= read_value("user.id")
    end
    
    def name
      @name ||= read_value("user.name")
    end
     
    def user_domain_id
      @user_domain_id ||= read_value("user.domain.id")
    end
    
    def user_domain_name
      @user_domain_name ||= read_value("user.domain.name")
    end
    
    def domain_id
      @domain_id ||= read_value("domain.id")
    end
    
    def domain_name
      @domain_name ||= read_value("domain.name")
    end
    
    def project_id
      @project_id ||= read_value("project.id")
    end
    
    def project_name
      @project_name ||= read_value("project.name")
    end
    
    def project_domain_id
      @project_domain_id ||= read_value("project.domain.id")
    end
    
    def project_domain_name
      @project_domain_name ||= read_value("project.domain.name")
    end
    
    def project_scoped
      @project_scoped ||= read_value("project")
    end
     
    protected
    
    def read_value(key)
      keys = key.split('.')
      result = @context
      keys.each do |k|
        return nil unless result
        result = result[k]
      end
      return result
    end
    
    # def init_from_token(token_hash)
    #   @context = token_hash
    #   @token = token_hash["value"]
    #
    #   user_params = user_params(token_hash)
    #   @id = user_params["id"] if user_params
    #   @name = user_params["name"] if user_params
    #   @user_domain_id = user_params["domain"]["id"] if user_params["domain"]
    #
    #
    #   #@domain_id =
    # end
    
    # def user_params(token_hash)
    #   token_hash["user"]
    # end
  
    # def add_user_methods(token)
    #   user_params = (token["user"] || token[:user])
    #   return unless user_params
    #
    #   user_params.each do |key,value|
    #     key=key.to_s.gsub(/\.|\s|-|\/|\'/, '_').downcase.to_sym
    #     method_name = key
    #     if key==:domain_id
    #       method_name=:user_domain_id
    #     end
    #     self.instance_variable_set("@#{method_name}", value)
    #     self.class.send(:define_method, method_name, proc{self.instance_variable_get("@#{method_name}")})
    #   end
    # end
    #
    # def to_object(token)
    #   if token.kind_of? Hash
    #     keys = token.keys
    #     struct_fields = keys.inject([]){|array,key| array << key.to_sym}
    #     struct = TokenStruct.new(*struct_fields)
    #     values = []
    #
    #     keys.each do |key|
    #       value = token[key]
    #       if (key.to_s=="expires_at" or key.to_s=="issued_at") and value.kind_of? String
    #         value = DateTime.parse(value)
    #       end
    #       values << create_methods(value)
    #     end
    #     return struct.new(*values)
    #   elsif token.kind_of? Array
    #     values = []
    #     token.each do |value|
    #       values << create_methods(value)
    #     end
    #     return values
    #   else
    #     return token
    #   end
    # end
  end
end

# module MonsoonIdentity
#   class TokenValue < Struct
#     undef []=
#
#     def initialize(*args, &block)
#       super(*args, &block)
#       members.each{ |member| instance_eval{ undef :"#{member}=" } }
#     end
#   end
# end