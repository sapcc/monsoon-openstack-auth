require "monsoon_identity/engine"
require "monsoon_identity/errors"
require "monsoon_identity/token_value"
require "monsoon_identity/context"
require "monsoon_identity/user"
require "monsoon_identity/auth"
require "monsoon_identity/controller"


module MonsoonIdentity
end

ActionController::Base.send(:include, MonsoonIdentity::Controller)
