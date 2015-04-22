module MonsoonOpenstackAuth
  # This class provides services defined in app/services/monsoon_openstack_auth
  class ServiceProvider

    def initialize(region,current_user)
      @region = region
      @current_user = current_user
    end 
    
    def method_missing(method_sym, *arguments, &block)
      return true if method_sym == :klass
      
      service = instance_variable_get("@#{method_sym.to_s}")
      
      unless service      
        service_class_name = "MonsoonOpenstackAuth::#{method_sym.to_s.classify}Service"
      
        klazz = begin
          Object.const_get(service_class_name)
        rescue
          raise "service #{service_class_name} not found!"
        end

        unless klazz < MonsoonOpenstackAuth::OpenstackServiceProvider::Base
          raise "service #{service_class_name} is not a subclass of MonsoonOpenstackAuth::OpenstackServiceProvider::Base"  
        end

        service = klazz.new(@region,@current_user)
        instance_variable_set("@#{method_sym.to_s}", service)
      end
      
      return service
    end
  end
end