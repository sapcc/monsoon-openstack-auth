module MonsoonOpenstackAuth
  module OpenstackServiceProvider
    class Base
      def self.descendants
        ObjectSpace.each_object(Class).select { |klass| klass < self }
      end
      
      def initialize(region,current_user)
        @region = region
        @current_user = current_user
        
        if MonsoonOpenstackAuth.configuration.debug
          MonsoonOpenstackAuth.logger.info "MonsoonOpenstackAuth::OpenstackServiceProvider::Base: service #{self.class.name} initialized" 
        end
      end
      
    end  
  end
end