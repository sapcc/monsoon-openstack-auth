module MonsoonOpenstackAuth
  class UnknownConnectionDriver < StandardError; end
  class MalformedToken < StandardError; end
  class InvalidRegion < StandardError; end
  class InvalidAuthToken < StandardError; end
  class InvalidUserCredentials < StandardError; end
  class NotAuthorized < StandardError; end
  class ConfigurationError < StandardError; end
  class InterfaceNotImplementedError < NoMethodError; end
end