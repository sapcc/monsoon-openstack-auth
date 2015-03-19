module MonsoonIdentity
  class User
    attr_reader :context
    
    def initialize(token)
      @token = token
      add_user_methods(token)
      #@token_as_struct = to_obj(token)
     
      # user_params = token["user"] || token[:user]
      # @name = user_params["name"] || user_params[:name] if user_params
      #
    
      #to_obj(token)
      # token=token,
      # user=token.user['name'],
      # user_domain_id=token.user_domain_id,
      # project_id=token.project['id'],
      # project_name=token.project['name'],
      # domain_id=token.domain['id'],
      # domain_name=token.domain['name'],
      # enabled=True,
      # service_catalog=token.serviceCatalog,
      # roles=token.roles,
      # endpoint=endpoint,
      # services_region=services_region)
    
      @context = MonsoonIdentity::Context.new(self,token)
    end
     
    def domains(region, options={per_page: 30, page: 1})
      domains_response = MonsoonIdentity::Auth.keystone_connection(region).request({
        method: 'GET', 
        path: 'domains', 
        headers: {'X-Auth-Token' => @token[:value]}, 
        query: {per_page: options[:per_page], page: options[:page]}
      })
      
      if domains_response and domains_response.body 
        domains_response.body["domains"] 
      else
        []
      end
    end
    
    def domain(region, domain_id, options={per_page: 10, page: 1})
      domains_response = MonsoonIdentity::Auth.keystone_connection(region).request({
        method: 'GET', 
        path: "domains/#{domain_id}", 
        headers: {'X-Auth-Token' => @token[:value]}, 
        query: {per_page: options[:per_page], page: options[:page]}
      })
      
      if domains_response and domains_response.body 
        domains_response.body["domains"] 
      else
        []
      end
    end
    
     
    protected
  
    def add_user_methods(token)
      user_params = (token["user"] || token[:user])
      return unless user_params
    
      user_params.each do |key,value|
        key=key.to_s.gsub(/\.|\s|-|\/|\'/, '_').downcase.to_sym
        method_name = key
        if key==:domain_id
          method_name=:user_domain_id
        end
        self.instance_variable_set("@#{method_name}", value)
        self.class.send(:define_method, method_name, proc{self.instance_variable_get("@#{method_name}")})
      end 
    end
  
    def to_object(token)
      if token.kind_of? Hash
        keys = token.keys
        struct_fields = keys.inject([]){|array,key| array << key.to_sym}
        struct = TokenStruct.new(*struct_fields)
        values = []
    
        keys.each do |key|
          value = token[key]
          if (key.to_s=="expires_at" or key.to_s=="issued_at") and value.kind_of? String
            value = DateTime.parse(value)
          end
          values << create_methods(value) 
        end
        return struct.new(*values)
      elsif token.kind_of? Array
        values = []
        token.each do |value|
          values << create_methods(value)
        end
        return values
      else
        return token  
      end
    end
  end
end