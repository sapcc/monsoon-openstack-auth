module OpenstackService
  class Volume < OpenstackServiceProvider::FogProvider
    
    def driver(auth_params)
      Fog::Volume::OpenStack.new(auth_params)
    end
  end
end