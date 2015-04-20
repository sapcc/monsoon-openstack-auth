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

# require "monsoon_openstack_auth/authorization/policy"
# require "monsoon_openstack_auth/authorization/security_violation"
require "monsoon_openstack_auth/authorization"

module MonsoonOpenstackAuth
  class << self
    attr_accessor :configuration
  end
  
  def self.configure
    self.configuration ||= MonsoonOpenstackAuth::Configuration.new
    yield(configuration)
    load_policy
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
    rescue MonsoonOpenstackAuth::Authorization::PolicyFileNotFound => e
      Rails.logger.info "Could not load policy file"
    end
  end

end

ActionController::Base.send(:include, MonsoonOpenstackAuth::Controller)
