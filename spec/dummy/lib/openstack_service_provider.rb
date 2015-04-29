module OpenstackServiceProvider
  
  module Services
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :helper_method, :services
    end

    module InstanceMethods
      def services
        unless @services
          if MonsoonOpenstackAuth.configuration.connection_driver and 
            MonsoonOpenstackAuth.configuration.connection_driver.endpoint and 
            @monsoon_openstack_auth and logged_in?
            
            @services = OpenstackServiceProvider::ServicesManager.new(
              MonsoonOpenstackAuth.configuration.connection_driver.endpoint,
              @monsoon_openstack_auth.region,
              current_user)
          end
        end
        @services
      end
    end
  end
  
  class ServicesManager
    def initialize(endpoint,region,current_user)
      @endpoint = endpoint
      @region = region
      @current_user = current_user
    end 
    
    def method_missing(method_sym, *arguments, &block)
      return true if method_sym == :klass
      
      service = instance_variable_get("@#{method_sym.to_s}")
      
      unless service      
        service_class_name = "OpenstackService::#{method_sym.to_s.classify}"
      
        klazz = begin
          eval(service_class_name)
        rescue
          raise "service #{service_class_name} not found!"
        end

        unless klazz < OpenstackServiceProvider::BaseProvider
          raise "service #{service_class_name} is not a subclass of OpenstackServiceProvider::BaseProvider"  
        end

        service = klazz.new(@endpoint,@region,@current_user)
        instance_variable_set("@#{method_sym.to_s}", service)
      end
      
      return service
    end
  end
  
  class BaseProvider
    def initialize(endpoint,region,current_user)
      @endpoint = endpoint
      @region = region
      @current_user = current_user
    end
  end
  
  class FogProvider < BaseProvider
    def initialize(endpoint,region,current_user)
      super

      @auth_params = {
        provider: 'openstack',
        openstack_auth_token: @current_user.token,
        openstack_auth_url: @endpoint,
        openstack_region: @region
      }
      
      @driver = driver(@auth_params)
    end
    
    def driver(auth_params)
      raise "Not implemented yet!"
    end
    
    def method_missing(method_sym, *arguments, &block)
      @driver.send(method_sym, arguments)
    end
  end
  
end