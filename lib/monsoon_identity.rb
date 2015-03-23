require "monsoon_identity/configuration"
require "monsoon_identity/engine"
require "monsoon_identity/errors"
require "monsoon_identity/token_value"
require "monsoon_identity/context"
require "monsoon_identity/user"
require "monsoon_identity/session"
require "monsoon_identity/auth"
require "monsoon_identity/controller"


module MonsoonIdentity
  class << self
    attr_accessor :configuration
  end
  
  def self.configure
    self.configuration ||= MonsoonIdentity::Configuration.new
    yield(configuration)
  end
end

ActionController::Base.send(:include, MonsoonIdentity::Controller)

