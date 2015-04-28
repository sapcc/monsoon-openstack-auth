require "monsoon_fog"
require "monsoon_openstack_auth/driver_interface"
require "monsoon_openstack_auth/driver/default"
require "monsoon_openstack_auth/configuration"
require "monsoon_openstack_auth/api_client"
require "monsoon_openstack_auth/engine"
require "monsoon_openstack_auth/errors"
require "monsoon_openstack_auth/user"
require "monsoon_openstack_auth/session_store"
require "monsoon_openstack_auth/session"
require "monsoon_openstack_auth/controller"

require "monsoon_openstack_auth/authorization"

module MonsoonOpenstackAuth
  class LoggerWrapper
    def initialize(logger)
      @logger = logger
    end
    
    def method_missing(method_sym, *arguments, &block)
      message = arguments.first
      message = "[Monsoon Openstack Auth] #{message}" if message.is_a?(String)
      @logger.send(method_sym,message)
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
    @api_connections[region] ||= MonsoonOpenstackAuth::ApiClient.new(region)
    @api_connections[region]
  end
  
  def self.policy_engine
    @policy_engine
  end
  
  def self.load_policy
    begin 
      policy_json = File.read(Rails.root.join(configuration.authorization.policy_file_path))
      @policy_engine = MonsoonOpenstackAuth::Authorization::PolicyEngine.new(policy_json)
      puts "[Monsoon Openstack Auth]: policy loaded!"
      MonsoonOpenstackAuth.logger.info "policy loaded!" 
    rescue => e
      puts "[Monsoon Openstack Auth] Could not load policy file. #{e.message}"
      MonsoonOpenstackAuth.logger.info "Could not load policy file. #{e.message}"
      return false
    end
  end

end

ActionController::Base.send(:include, MonsoonOpenstackAuth::Controller)
