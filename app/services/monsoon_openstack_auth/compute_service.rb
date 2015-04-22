module MonsoonOpenstackAuth
  class ComputeService < MonsoonOpenstackAuth::OpenstackServiceProvider::Fog
    
    def driver(auth_params)
      Fog::Compute::OpenStack.new(auth_params)
    end
  end
end