require "monsoon_openstack_auth/authentication/errors"
require "monsoon_openstack_auth/authentication/auth_user"
require "monsoon_openstack_auth/authentication/session_store"
require "monsoon_openstack_auth/authentication/auth_session"

module MonsoonOpenstackAuth
  # This module is included in a rails controller
  module Authentication
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    
      base.send :helper_method, :current_user, :logged_in?, :services
    end

    module ClassMethods
      def skip_authentication(options={})
        prepend_before_filter options do
          @_skip_authentication=true
        end
      end

      def api_authentication_required(options={})
        authentication_required options.merge raise_error:true
      end

      def authentication_required(options={})
        raise_error = options[:raise_error]

        reg = options.delete(:region)
        org = options.delete(:organization)
        prj = options.delete(:project)

        Rails.logger.debug "authentication_required region 1 #{reg}"

        raise MonsoonOpenstackAuth::Authentication::InvalidRegion.new("A region should be provided") unless reg

        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authentication") }) do
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

          raise MonsoonOpenstackAuth::Authentication::InvalidRegion.new("A region should be provided") unless region
          @monsoon_openstack_auth = MonsoonOpenstackAuth::Authentication::AuthSession.check_authentication(self, region, organization: organization, project: project,raise_error:raise_error)
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
    end
    
  end
end