module MonsoonOpenstackAuth
  module ConnectionDriver
    class UnknownConnectionDriver < StandardError; end
    class MalformedApiEndpoint < StandardError; end
    class ConfigurationError < StandardError; end
    class InterfaceNotImplementedError < NoMethodError; end
  end
end