module MonsoonOpenstackAuth
  module Driver
    class Default < MonsoonOpenstackAuth::DriverInterface
      class << self
        attr_accessor :api_endpoint, :api_userid, :api_password
      end
      
      def initialize(region)
        if self.class.api_endpoint.nil? and self.class.api_userid.nil? and self.class.api_password.nil?
          raise ConfigurationError.new("Api credentials not provided! Please provide 
            connection_driver.api_endpoint, connection_driver.api_userid and 
            connection_driver.api_password (in initializer).")
        end    
        
        @fog = Fog::IdentityV3::OpenStack.new({
          openstack_region:   region,
          openstack_auth_url: MonsoonOpenstackAuth::Driver::Default.api_endpoint,
          openstack_userid:   MonsoonOpenstackAuth::Driver::Default.api_userid,
          openstack_api_key:  MonsoonOpenstackAuth::Driver::Default.api_password
        })
        self
      end  
      
      def validate_token(auth_token)
        HashWithIndifferentAccess.new(@fog.tokens.validate(auth_token).attributes)
      end
    
      def authenticate_with_credentials(username,password, scope=nil)
        auth = {auth:{identity: {methods: ["password"],password:{user:{id: username,password: password}}}}}
        auth[:auth][:scope]=scope if scope
        #Rails.logger.info "Monsoon Openstack Auth: authenticate_with_credentials -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end

      def authenticate_with_token(token, scope=nil)
        auth = {auth:{identity: {methods: ["token"],token:{ id: token}}}}
        auth[:auth][:scope]=scope if scope
        Rails.logger.info "Monsoon Openstack Auth: authenticate_with_token -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end

      def authenticate_external_user(username, scope=nil)
        #TODO: authenticate external user
        #REMOTE_USER=d000000
        #REMOTE_DOMAIN=test

        auth = { auth: { identity: {methods: ["external"], external:{user: username }}}}
        auth[:auth][:scope]=scope if scope
        Rails.logger.info "Monsoon Openstack Auth: authenticate_external_user -> #{auth}" if MonsoonOpenstackAuth.configuration.debug
        HashWithIndifferentAccess.new(@fog.tokens.authenticate(auth).attributes)
      end
      
      ################## Not part of interface ################
      def user_domains(userid,options={per_page: 30, page: 1})    
        user = @fog.users.find_by_id(userid)
        projects = user.projects if user
        if projects
          projects.collect{|project| project["domain"] || { "name" => project["domain_id"], "id" => project["domain_id"] }  }.uniq
        else
          []
        end
      end
  
      def domain(domain_id)
        @fog.domains.find_by_id(domain_id)
      end
  
      def domain_projects(domain_id)
        @fog.projects.all(domain_id:domain_id) 
      end
  
      def project(project_id)
        @fog.projects.find_by_id(project_id) 
      end
      ##########################################################
      
    end
  end
end