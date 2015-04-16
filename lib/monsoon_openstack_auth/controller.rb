require 'hashie'

module MonsoonOpenstackAuth
  module Controller
    def self.included(base)
      base.send :extend, ClassMethods
      base.helper_method :current_user, :logged_in?
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

      def authorization_required(options={})
        before_filter do |f|
          enforce_it = true
          authority_action = f.action_name.to_sym
          if options[:except]
            if options[:except].include?(authority_action)
              enforce_it = false
            end
          end
          if options[:only] && enforce_it
            unless options[:only].include?(authority_action)
              enforce_it = false
            end
          end

          enforce f.params if enforce_it
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
      def authorize_context(context, resource, options = {})
        @authority_context = context
        @authority_resource = resource
      end

      # Allows defining and overriding a controller's map of its actions to the model's authorizer methods
      #
      # @param [Hash] action_map - controller actions and methods, to be merged with existing action_map
      def authorization_actions(action_map)
        authorization_action_map.merge!(overridden_actions(action_map))
        authorization_action_map.merge!(action_map.symbolize_keys)
      end

      # The controller action to authority action map used for determining
      # which Rails actions map to which authority actions (ex: index to read)
      #
      # @return [Hash] A duplicated copy of the configured controller_action_map
      def authorization_action_map
        @authorization_action_map ||= MonsoonOpenstackAuth.configuration.authorization_controller_action_map.dup
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

      def enforce params
        authority_action = self.class.authorization_action_map[action_name.to_sym]
        authority_context = controller_name
        application_name = MonsoonOpenstackAuth.configuration.authorization_context
        os_action = "#{application_name}:#{authority_context}_#{authority_action}"
        params_mash = Hashie::Mash.new(params)
        MonsoonOpenstackAuth::Policy.instance.enforce(current_user, [os_action], params_mash)
      end
      alias_method :authorize_action_for, :enforce

    end
  end
end
