module MonsoonIdentity
  class InvalidRegion < StandardError; end
  class InvalidAuthToken < StandardError; end
  class NotAuthorized < StandardError; end
  class ConfigurationError < StandardError; end
end