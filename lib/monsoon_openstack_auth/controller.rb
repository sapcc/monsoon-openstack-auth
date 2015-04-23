module MonsoonOpenstackAuth
  module Controller
    def self.included(base)
      base.send :extend, ClassMethods
      base.helper_method :current_user, :logged_in?, :services
      base.send :include, MonsoonOpenstackAuth::Controller::InstanceMethods
    end
 
    module ClassMethods
      
      def skip_authentication(options={})
        prepend_before_filter options do 
          @_skip_authentication=true 
        end
      end

      def authentication_required(options={})
        reg = options.delete(:region)
        org = options.delete(:organization)
        prj = options.delete(:project)

        raise MonsoonOpenstackAuth::InvalidRegion.new("A region should be provided") unless reg

        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authentication") } ) do
          region = reg.kind_of?(Proc) ? reg.call(self) : self.send(reg.to_sym)
   
          get_value = lambda do |method_name| 
            result = nil
            if method_name
              if method_name.kind_of?(Proc)
                result = method_name.call(self)
              elsif self.respond_to?(method_name.to_sym)
                result = self.send(method_name.to_sym)
              end
            end
            (result.is_a?(String) and result.empty?) ? nil : result
          end    
              
          organization = get_value.call(org)
          project = get_value.call(prj)

          raise MonsoonOpenstackAuth::InvalidRegion.new("A region should be provided") unless region
          @monsoon_openstack_auth = MonsoonOpenstackAuth::Session.check_authentication(self, region, organization: organization, project: project)
        end
      end
    end
 
    module InstanceMethods
        
      def current_user
        @monsoon_openstack_auth.nil? ? nil : @monsoon_openstack_auth.user
      end
      
      def logged_in?
        @monsoon_openstack_auth.nil? ? false : @monsoon_openstack_auth.logged_in?
      end
      
      def services
        @monsoon_openstack_auth.nil? ? nil : @monsoon_openstack_auth.services
      end
    end
  end
end
