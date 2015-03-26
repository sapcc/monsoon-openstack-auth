require "monsoon_identity/configuration"
require "monsoon_identity/api_client"
require "monsoon_identity/engine"
require "monsoon_identity/errors"
require "monsoon_identity/user"
require "monsoon_identity/session_store"
require "monsoon_identity/session"
require "monsoon_identity/controller"


module MonsoonIdentity
  class << self
    attr_accessor :configuration
  end
  
  def self.configure
    self.configuration ||= MonsoonIdentity::Configuration.new
    yield(configuration)
  end
  
  def self.api_client(region)
    @api_connections = {} unless @api_connections
    @api_connections[region] ||= MonsoonIdentity::ApiClient.new(region)
    @api_connections[region]
  end  
end

ActionController::Base.send(:include, MonsoonIdentity::Controller)
