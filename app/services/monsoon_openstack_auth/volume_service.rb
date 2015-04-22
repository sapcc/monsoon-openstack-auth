module MonsoonOpenstackAuth
  class VolumeService < MonsoonOpenstackAuth::OpenstackServiceProvider::Fog
    
    def driver(auth_params)
      Fog::Volume::OpenStack.new(auth_params)
    end
  end
end