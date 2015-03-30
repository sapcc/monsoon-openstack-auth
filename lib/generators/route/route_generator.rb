class RouteGenerator < Rails::Generators::Base
  #source_root File.expand_path('../templates', __FILE__)
  
  def add_route
    route "mount MonsoonIdentity::Engine => '/monsoon_identity'"
  end
end
