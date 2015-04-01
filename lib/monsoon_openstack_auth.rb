require "monsoon_fog"
require "monsoon_openstack_auth/configuration"
require "monsoon_openstack_auth/api_client"
require "monsoon_openstack_auth/engine"
require "monsoon_openstack_auth/errors"
require "monsoon_openstack_auth/user"
require "monsoon_openstack_auth/session_store"
require "monsoon_openstack_auth/session"
require "monsoon_openstack_auth/controller"

module MonsoonOpenstackAuth
  class << self
    attr_accessor :configuration
  end
  
  def self.configure
    self.configuration ||= MonsoonOpenstackAuth::Configuration.new
    yield(configuration)
  end
  
  def self.api_client(region)
    @api_connections = {} unless @api_connections
    @api_connections[region] ||= MonsoonOpenstackAuth::ApiClient.new(region)
    @api_connections[region]
  end  
end

ActionController::Base.send(:include, MonsoonOpenstackAuth::Controller)
