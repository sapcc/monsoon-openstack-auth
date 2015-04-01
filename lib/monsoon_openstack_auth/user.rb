module MonsoonOpenstackAuth
  class User
    attr_reader :context, :services_region#, :token, :id, :name, :user_domain_id, :domain_id, :domain_name, :project_id, :project_name, 
      #:service_catalog, :roles, :endpoint, :projects, :region
    
    def initialize(region,token_hash)
      raise MonsoonOpenstackAuth::MalformedToken.new("Token is nil.") if token_hash.nil?
      raise MonsoonOpenstackAuth::MalformedToken.new("Token should be a hash.") unless token_hash.is_a?(Hash)
      @services_region = region
      @context = token_hash
    end

    def enabled?
      @enabled
    end

    # Returns the token value (auth_token)  
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
    
    def domain_scoped
      @domain_scoped ||= read_value("domain")
    end
    
    def token_expires_at
      @token_expires_at ||= DateTime.parse(@context["expires_at"])
    end
    
    def token_expired?
      token_expires_at<Time.now
    end
    
    def token_issued_at
      @token_issued_at ||= DateTime.parse(@context["issued_at"])
    end
    
    def service_catalog
      @service_catalog ||= (@context["catalog"] || @context["serviceCatalog"] || [])
    end
    
    def has_service?(type)
      catch(:found) do 
        service_catalog.each { |service| throw(:found, true) if service["type"]==type }
        # not found
        false
      end
    end
    
    def roles
      @roles ||= (@context["roles"] || read_value("user.roles") || [])
    end
    
    def has_role?(name)
      catch(:found) do 
        roles.each { |role| throw(:found, true) if role["name"]==name }
        # not found
        false
      end
    end
 
    def admin?
      if @is_admin.nil?
        @is_admin = catch(:found) do
          # return true if found
          roles.each{ |role| throw(:found, true) if role["name"]=="admin" } 
          # else return false
          false
        end
      end
      @is_admin
    end
    
    # Returns the first endpoint region for first non-identity service
    # in the service catalog
    def default_services_region
      @default_services_region ||= catch(:found) do
        service_catalog.each do |service|
          throw(:found, service["endpoints"].first["region"]) if service["type"]!="identity" and service["endpoints"] and service["endpoints"].first
        end
        ''
      end
      @default_services_region.empty? ? nil : @default_services_region
    end
    
    # Returns list of unique region name values found in service catalog 
    def available_services_regions
      unless @regions
        @regions = []
        service_catalog.each do |service|
          next if service["type"]=="identity"
          (service["endpoints"] || []).each do |endpint|
            @regions << endpint['region']
          end  
        end
        @regions.uniq!
      end
      @regions
    end  
     
    protected
    
    # Returns a value from context for given key.
    # example for key: "user.id"
    def read_value(key)
      keys = key.split('.')
      result = @context
      keys.each do |k|
        return nil unless result
        result = result[k]
      end
      return result
    end
  end
end