require "monsoon_openstack_auth/authentication/errors"
require "monsoon_openstack_auth/authentication/auth_default_domain"
require "monsoon_openstack_auth/authentication/auth_user"
require "monsoon_openstack_auth/authentication/session_store"
require "monsoon_openstack_auth/authentication/auth_session"

module MonsoonOpenstackAuth
  # This module is included in a rails controller
  module Authentication
    def self.included(base)
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
    
      base.send :helper_method, :current_user, :logged_in?, :services, :auth_default_domain
    end
    
    def self.get_filter_value(controller,method_name)
      result = nil
      if method_name
        if method_name.kind_of?(Proc)
          result = method_name.call(controller)
        elsif controller.respond_to?(method_name.to_sym)
          result = controller.send(method_name.to_sym)
        end
      end
      (result.is_a?(String) and result.empty?) ? nil : result
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
        org = options.delete(:domain) unless org
        prj = options.delete(:project)

        # use default region from config
        reg = -> c {MonsoonOpenstackAuth.configuration.default_region} unless reg

        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authentication") }) do
          region        = Authentication.get_filter_value(self,reg)
          
          # region is required
          raise MonsoonOpenstackAuth::Authentication::InvalidRegion.new("A region should be provided") unless region
            
          @auth_session = AuthSession.check_authentication(self, region, {
            domain: Authentication.get_filter_value(self,org), 
            project: Authentication.get_filter_value(self,prj),
            raise_error:raise_error
          })
          @current_user = @auth_session.user if @auth_session
        end
      end
    end

    module InstanceMethods 
      def auth_session
        @auth_session
      end
      
      def current_user
        @current_user
      end

      def logged_in?
        !@current_user.nil?
      end
      
      def auth_default_domain
        MonsoonOpenstackAuth.default_domain
      end
    end
  end
end