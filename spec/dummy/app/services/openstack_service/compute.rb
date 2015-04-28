module OpenstackService
  class Compute < OpenstackServiceProvider::FogProvider
    
    def driver(auth_params)
      Fog::Compute::OpenStack.new(auth_params)
    end
  end
end