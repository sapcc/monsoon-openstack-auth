require "monsoon_fog"

require "monsoon_openstack_auth/connection_driver/errors"
require "monsoon_openstack_auth/connection_driver/interface"
require "monsoon_openstack_auth/connection_driver/default"
require "monsoon_openstack_auth/api_client"

require "monsoon_openstack_auth/engine"
require 'monsoon_openstack_auth/authorization'
require "monsoon_openstack_auth/authentication"
require "monsoon_openstack_auth/configuration"

require "monsoon_openstack_auth/cache/rails_memory_cache"
require "monsoon_openstack_auth/cache/noop_cache"

module MonsoonOpenstackAuth
  class ApiError < StandardError;
  end

  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end

    def method_missing(method_sym, *arguments, &block)
      message = arguments.first
      message = "[Monsoon Openstack Auth] #{message}" if message.is_a?(String)
      @logger.send(method_sym, message)
    end
  end

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= MonsoonOpenstackAuth::Configuration.new
    yield(configuration)
  end

  def self.logger
    @logger ||= configuration.logger
  end

  def self.api_client(region)
    @api_connections = {} unless @api_connections

    # create and cache api_connection for requested region.
    unless @api_connections[region]
      @api_connections[region] = begin
        MonsoonOpenstackAuth::ApiClient.new(region)
      rescue MonsoonOpenstackAuth::ConnectionDriver::ConnectionError => e
        self.logger.error(e.message)
        raise ApiError.new("Service user unavailable. Could not authenticate service user.")
      end
    end
    @api_connections[region]
  end

  def self.policy_engine
    MonsoonOpenstackAuth.load_policy if configuration.authorization.reload_policy || @policy_engine.nil?
    @policy_engine
  end

  def self.load_policy
    begin
      if configuration.authorization.policy_file_path.is_a? Array
        pol_files = configuration.authorization.policy_file_path
      else
        pol_files = [configuration.authorization.policy_file_path]
      end
      combined_policies = {}
      pol_files.each do |pol_file|
        combined_policies.merge!(JSON.parse(File.read(pol_file))) { |key, v1, v2| v1 }
      end
      @policy_engine = MonsoonOpenstackAuth::Authorization::PolicyEngine.new(combined_policies)
      if !Rails or Rails.env != 'test'
        MonsoonOpenstackAuth.logger.info "policy loaded!"
      end
    rescue => e
      MonsoonOpenstackAuth.logger.info "Could not load policy file. #{e.message}"
      return false
    end
  end

  # def self.load_default_domain
  #   @default_domain = begin
  #     self.api_client(self.configuration.default_region).default_domain
  #   rescue ApiError, MonsoonOpenstackAuth::ConnectionDriver::ConnectionError => e
  #     nil
  #   end
  #
  #   raise ApiError.new("Could not load default domain '#{self.configuration.default_domain_name}'") unless @default_domain
  # end
  #
  # def self.default_domain
  #   # load and cache default domain unless available
  #   self.load_default_domain unless @default_domain
  #   @default_domain
  # end

end

ActionController::Base.send(:include, MonsoonOpenstackAuth::Authentication)
ActionController::Base.send(:include, MonsoonOpenstackAuth::Authorization)
