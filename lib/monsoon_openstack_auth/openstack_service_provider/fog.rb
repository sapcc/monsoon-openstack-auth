module MonsoonOpenstackAuth
  module OpenstackServiceProvider
    class Fog < Base # fog provider
      def initialize(region,current_user)
        super
        
        if MonsoonOpenstackAuth::Driver::Default.api_endpoint
          @auth_params = {
            provider: 'openstack',
            openstack_auth_token: @current_user.token,
            openstack_auth_url: MonsoonOpenstackAuth::Driver::Default.endpoint,
            openstack_region: @region
          }
          if MonsoonOpenstackAuth.configuration.debug
            log = "MonsoonOpenstackAuth::OpenstackServiceProvider::Fog: "
            log += "token: #{@current_user.token} "
            log += "endpoint: #{MonsoonOpenstackAuth::Driver::Default.endpoint} "
            log += "region: #{@region}"
            Rails.logger.info log
          end
        end
        
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
end