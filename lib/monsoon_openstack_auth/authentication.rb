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

        org             = options.delete(:organization)
        org             = options.delete(:domain) unless org
        prj             = options.delete(:project)
        org_name        = options.delete(:domain_name)

        # The redirect_to parameter defines a string or callback which returns a string.
        # This callback is called after user has logged on.
        # There is a problem with this callback. The before filter "authentication_required" is called
        # in context of the host app. Then it redirects to the sessions controller of the auth gem 
        # if user isn't logged in. Thus, the host app loses the control and the callback is not available
        # in the sessions controller. In order to make the callback abailable in other context we save 
        # it in a static variable of AuthSession and give the key (id) to the session.
        redirect_to_callback_id = AuthSession.add_redirect_to_callback(options.delete(:redirect_to))
        
        do_rescope = options.delete(:rescope)
        do_rescope = do_rescope.nil? ? true : do_rescope 

        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authentication") }) do       
          if !raise_error and session and !session.loaded?
            session[:init] = true 
          end
          
          auth_session_params = {
            domain: Authentication.get_filter_value(self,org), 
            domain_name: Authentication.get_filter_value(self,org_name), 
            project: Authentication.get_filter_value(self,prj),
            raise_error:raise_error
          } 
          # add the id of callback to session params  
          auth_session_params[:redirect_to_callback_id] = redirect_to_callback_id if redirect_to_callback_id
          
          @auth_session = AuthSession.check_authentication(self, auth_session_params)
          
          # @current_user = @auth_session.user if @auth_session
          
          if @auth_session
            # rescope token to domain and project unless prevented 
            authentication_rescope_token if do_rescope
          end
        end
      end
    end

    module InstanceMethods 
      def auth_session
        @auth_session
      end
      
      def current_user
        if auth_session
          auth_session.user
        else
          AuthSession.load_user_from_session(self).user rescue nil
        end
      end

      def logged_in?
        !current_user.nil?
      end
      
      def authentication_rescope_token
        @auth_session.rescope_token if @auth_session
      end
      
      def redirect_to_login_form
        @auth_session.redirect_to_login_form if @auth_session
      end
      
    end
  end
end