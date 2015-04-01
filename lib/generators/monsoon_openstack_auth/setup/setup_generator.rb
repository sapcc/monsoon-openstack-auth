module MonsoonOpenstackAuth
  class SetupGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def add_route
      route "mount MonsoonOpenstackAuth::Engine => '/auth'"
    end
  
    def copy_initializer_file
      copy_file "initializer.rb", "config/initializers/monsoon_openstack_auth.rb"
    end
    
    def copy_env_file
      copy_file "env", ".env"
    end
  end
end
