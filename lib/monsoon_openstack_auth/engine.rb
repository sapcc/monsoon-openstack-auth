module MonsoonOpenstackAuth
  class Engine < ::Rails::Engine
    isolate_namespace MonsoonOpenstackAuth
    
    config.generators do |g|
      g.test_framework      :rspec,        :fixture => false
      g.fixture_replacement :factory_girl, :dir => 'spec/factories'
      g.assets false
      g.helper false
    end
    
    initializer "monsoon_openstack_auth.assets.precompile" do |app|
      app.config.assets.precompile += %w(application.css)
    end
      
    config.after_initialize do
      #MonsoonOpenstackAuth.load_policy
      #MonsoonOpenstackAuth.load_default_domain unless Rails.env=='test'
    end
  end
end
