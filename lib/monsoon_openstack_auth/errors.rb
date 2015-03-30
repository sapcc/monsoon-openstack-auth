module MonsoonOpenstackAuth
  class MalformedToken < StandardError; end
  class InvalidRegion < StandardError; end
  class InvalidAuthToken < StandardError; end
  class InvalidUserCredentials < StandardError; end
  class NotAuthorized < StandardError; end
  class ConfigurationError < StandardError; end
end