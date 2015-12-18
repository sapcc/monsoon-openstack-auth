require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib')
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    
    config.keystone_endpoint = ENV['MONSOON_OPENSTACK_AUTH_API_ENDPOINT']
    config.service_user_id   = ENV['MONSOON_OPENSTACK_AUTH_API_USERID']
    config.service_user_password = ENV['MONSOON_OPENSTACK_AUTH_API_PASSWORD']
    config.service_user_domain_name   = ENV['MONSOON_OPENSTACK_AUTH_DOMAIN']
    config.default_region = 'europe'
  end
end

