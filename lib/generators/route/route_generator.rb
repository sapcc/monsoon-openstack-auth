class RouteGenerator < Rails::Generators::Base
  #source_root File.expand_path('../templates', __FILE__)
  
  def add_route
    route "mount MonsoonOpenstackAuth::Engine => '/monsoon_openstack_auth'"
  end
end
