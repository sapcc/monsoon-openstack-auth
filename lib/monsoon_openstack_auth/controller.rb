require 'hashie'

module MonsoonOpenstackAuth
  module Controller

    extend ActiveSupport::Concern
    include ActiveSupport::Rescuable unless defined?(Rails)

    def self.security_violation_callback
      Proc.new do |exception|
        # Through the magic of `instance_exec` `ActionController::Base#rescue_from`
        # can call this proc and make `self` the actual controller instance
        self.send(MonsoonOpenstackAuth.configuration.authorization.security_violation_handler, exception)
      end
    end

    included do
      rescue_from(MonsoonOpenstackAuth::Authorization::SecurityViolation, :with => MonsoonOpenstackAuth::Controller.security_violation_callback)
      class_attribute :authorization_resource, :instance_reader => false
    end

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

      def skip_authorization(options={})
        prepend_before_filter options do
          @_skip_authorization=true
        end
      end

      def authentication_required(options={})
        reg = options.delete(:region)
        org = options.delete(:organization)
        prj = options.delete(:project)

        raise MonsoonOpenstackAuth::InvalidRegion.new("A region should be provided") unless reg

        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authentication") }) do
          region = reg.kind_of?(Proc) ? reg.call(self) : self.send(reg.to_sym)

          if org
            if org.kind_of?(Proc)
              organization = org.call(self)
            else
              organization = self.send(org.to_sym) if self.respond_to?(org.to_sym)
            end
          end

          if prj
            if prj.kind_of?(Proc)
              project = prj.call(self)
            else
              project = self.send(prj.to_sym) if self.respond_to?(prj.to_sym)
            end
          end

          raise MonsoonOpenstackAuth::InvalidRegion.new("A region should be provided") unless region
          @monsoon_openstack_auth = MonsoonOpenstackAuth::Session.check_authentication(self, region, organization: organization, project: project)
        end
      end

      # Sets up before_filter to ensure user is allowed to perform a given controller action
      #
      # @param [Class OR Symbol] resource_or_finder - class whose authorizer
      # should be consulted, or instance method on the controller which will
      # determine that class when the request is made
      # @param [Hash] options - can contain :actions to
      # be merged with existing
      # ones and any other options applicable to a before_filter
      def authorization_actions_for(resource_or_finder, options = {})
        self.authorization_resource = resource_or_finder
        authorization_actions(overridden_actions(options))
        before_filter options.merge(unless: -> c { c.instance_variable_get("@_skip_authorization") }) do
          run_authorization_check options
        end
      end

      # Allows defining and overriding a controller's map of its actions to the model's authorizer methods
      #
      # @param [Hash] action_map - controller actions and methods, to be merged with existing action_map
      def authorization_actions(action_map)
        authorization_action_map.merge!(overridden_actions(action_map))
        authorization_action_map.merge!(action_map.symbolize_keys)
      end

      def authorization_action(action_map)
        MonsoonOpenstackAuth.logger.warn "authorization's `authorization_action` method has been renamed \
        to `authorization_actions` (plural) to reflect the fact that you can \
        set multiple actions in one shot. Please update your controllers \
        accordingly. (called from #{caller.first})".squeeze(' ')
        authorization_actions(action_map)
      end

      # Convenience wrapper for instance method
      def ensure_authorization_performed(options = {})
        after_filter(options.slice(:only, :except)) do |controller_instance|
          controller_instance.ensure_authorization_performed(options)
        end
      end

      # The controller action to authorization action map used for determining
      # which Rails actions map to which authorization actions (ex: index to read)
      #
      # @return [Hash] A duplicated copy of the configured controller_action_map
      def authorization_action_map
        @authorization_action_map ||= MonsoonOpenstackAuth.configuration.authorization.controller_action_map.dup
      end

      def overridden_actions(options = {})
        if forced_action = options.fetch(:all_actions, false)
          overridden_actions = authorization_action_map.inject({}) { |hash, (key, val)| hash.tap { |h| h[key] = forced_action } }
        end
        overridden_actions || options.fetch(:actions, {})
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
      
      attr_writer :authorization_performed

      def authorization_performed?
        !!@authorization_performed
      end

      def ensure_authorization_performed(options = {})
        return if authorization_performed?
        return if options[:if] && !send(options[:if])
        return if options[:unless] && send(options[:unless])
        raise AuthorizationNotPerformed, "No authorization was performed for #{self.class.to_s}##{self.action_name}"
      end

      protected

      # To be run in a `before_filter`; ensure this controller action is allowed for the user
      # Can be used directly within a controller action as well, given an instance or class with or
      # without options to delegate to the authorizer.
      #
      # @param [Class] authorization_resource, the model class associated with this controller
      # @param [Hash] options, arbitrary options hash to forward up the chain to the authorizer
      # @raise [MissingAction] if controller action isn't a key in `config.controller_action_map`
      def authorize_action_for(authorization_resource, options)

        # create a hash for non hash authorization objects
        unless authorization_resource.is_a? Hash
          hashed_resource =  Hashie::Mash.new({ authorization_resource.class.name.downcase.to_sym => authorization_resource.instance_values.symbolize_keys })
        else
          hashed_resource = authorization_resource
        end

        # `action_name` comes from ActionController
        authorization_action = self.class.authorization_action_map[action_name.to_sym]
        if authorization_action.nil?
          raise MissingAction.new("No authorization action defined for #{action_name}")
        end
        self.authorization_performed = true
        application_name = MonsoonOpenstackAuth.configuration.authorization.context
        authorization_resouce_name = options[:name] ? options[:name] : authorization_resource.class
        os_action = ("#{application_name}:#{authorization_resouce_name}_#{authorization_action}").downcase
        result = policy.enforce([os_action], hashed_resource)
        raise MonsoonOpenstackAuth::Authorization::SecurityViolation.new(authorization_user, os_action, authorization_resource) unless result
      end

=begin
      def enforce params
        authority_action = self.class.authorization_action_map[action_name.to_sym]
        authority_context = controller_name
        application_name = MonsoonOpenstackAuth.configuration.authorization.context
        os_action = "#{application_name}:#{authority_context}_#{authority_action}"
        params_mash = Hashie::Mash.new(params)
        #MonsoonOpenstackAuth::Policy.instance.enforce(current_user, [os_action], params_mash)
        result = @policy.enforce(os_action, params_mash)
        raise MonsoonOpenstackAuth::Authorization::SecurityViolation.new(current_user, os_action, params_mash) unless result
      end
      alias_method :authorize_action_for, :enforce
=end


      # Renders a static file to minimize the chances of further errors.
      #
      # @param [Exception] error, an error that indicates the user tried to perform a forbidden action.
      def authorization_forbidden(error)
        MonsoonOpenstackAuth.logger.warn(error.message)
        render :file => Rails.root.join('public', '403.html'), :status => 403, :layout => false
      end

      private

      # The `before_filter` that will be setup to run when the class method
      # `authorize_actions_for` is called
      def run_authorization_check options
        authorize_action_for instance_authorization_resource, options
      end

      def instance_authorization_resource
        return self.class.authorization_resource if self.class.authorization_resource.is_a?(Class)
        send(self.class.authorization_resource)
      rescue NoMethodError
        raise MissingResource.new(
                  "Trying to authorize actions for '#{self.class.authorization_resource}', but can't. \
          Must be either a resource class OR the name of a controller instance method that \
          returns one.".squeeze(' ')
              )
      end

      def policy
        @policy ||= MonsoonOpenstackAuth.policy_engine.policy(authorization_user)
      end

      # Convenience wrapper for sending configured `user_method` to extract the
      # request's current user
      #
      # @return [Object] the user object returned from sending the user_method
      def authorization_user
        user = send(MonsoonOpenstackAuth.configuration.authorization.user_method)
#        user.roles.each do |r|
#          r[:name] = "member"
#        end
        user
      end

      class MissingAction < StandardError;
      end
      class MissingResource < StandardError;
      end
      class AuthorizationNotPerformed < StandardError;
      end

    end
  end
end
