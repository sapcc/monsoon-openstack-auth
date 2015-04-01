MonsoonOpenstackAuth
=====================

Implements the authentication functionality using Keystone API.

Install
-------

```
$ [sudo] gem install monsoon-openstack-auth
```

### Gemfile


```
gem 'monsoon-openstack-auth', git: 'git://github.com/sapcc/monsoon/monsoon-openstack-auth.git'
```

Setup
-----

```
rails generate monsoon_openstack_auth:setup
```

Usage
-----

### Configuration
File: config/initializers/monsoon_openstack_auth.rb
```ruby
MonsoonOpenstackAuth.configure do |config|
  # api auth endpoint
  config.api_endpoint = 'http://localhost:8183/v3/auth/tokens'
  # api admin user
  config.api_userid   = 'admin'
  # api admin password
  config.api_password = 'secret'
  
  # optional, default=true
  config.token_auth_allowed = true
  # optional, default=true
  config.basic_atuh_allowed = true
  # optional, default=true
  config.sso_auth_allowed   = true
  # optional, default=true
  config.form_auth_allowed  = true
  
  # optional, default= last url before redirected to form
  #config.login_redirect_url = '/'
  
  # optional, default=false
  config.debug=false
end
```

#### Session Store
If this gem should support the form based login then the session store must be anything but cookie_store.

Example of setting up a ActiveRecord session_store (https://github.com/rails/activerecord-session_store)

File: Gemfile:
```ruby
gem 'activerecord-session_store'
```

```
rails generate active_record:session_migration
```

File: config/initializers/session_store.rb
```ruby
Rails.application.config.session_store :active_record_store, :key => '_monsoon_app_session'
```


### Controller

Example:
```ruby
DashboardController < ApplicationController
  authentication_required region: :get_region 

  def index
  end
  
  def get_region
    @region = params[:region_id]
  end
end
```

Example:
```ruby
DashboardController < ApplicationController
  authentication_required only: [:index], region: -> c {'europe'}, project: :get_project, organization: :get_organization 
  
  def index
  end
  
  def get_organization
    @organization_id = (controller_name == 'organizations') ? params[:id] : params[:organization_id]
  end
  
  def get_project
    @project_id = (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
end
```

Example: spec/dummy/app/controllers/dashboard_controller.rb

Develop
-------
```
git clone https://github.com/sapcc/monsoon/monsoon-openstack-auth.git
cd monsoon-openstack-auth
bundle install
cd spec/dummy
bundle exec rake db:migrate
bundle exec rails s
```