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

### Session Store
If this gem should support the form based login then the session store must be anything but cookie_store.

Example of setting up a ActiveRecord session_store (https://github.com/rails/activerecord-session_store)

File: Gemfile
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


## Controller

### authentication_required

```ruby
authentication_required options
```

options:

* region, required. Example: 'europe'
* organization, optional. Example: 'o-ghghad'
* project, optional. Example: 'p-jhjhhj'
* only, optional. Example only: [:index,:show]
* except, optional. Example except: [:index,:show]
* if, optional. Example if: -> c {c.params[:region_id].nil?}
* unless, optional

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

### skip_authentication

```ruby
skip_authentication options
```

options:

* only, optional. Example only: [:index,:show]
* except, optional. Example except: [:index,:show]
* if, optional. Example if: -> c {c.params[:region_id].nil?}
* unless, optional

### current_user

```ruby
current_user
```
Returns current_user if authenticated.
Also available in views!

### logged_in?

```ruby
current_user
```
Returns true if current_user is presented.
Also available in views!

### User Class
Instance methods:

* context, returns the token received by API
* enabled?, true if user is active (enabled)
* token, returns the token value (auth_token)  
* id, user id (obtained through the token)
* name, user name (obtained through the token)
* user_domain_id, received by scoped token
* user_domain_name, received by scoped token
* domain_id, scope (obtained through the token)
* domain_name, scope (obtained through the token)
* project_id, scope (obtained through the token)
* project_name, scope (obtained through the token)
* project_domain_id, scope (obtained through the token)
* project_domain_name, scope (obtained through the token)
* project_scoped, returns a hash (scope)
* domain_scoped, returns a hash (scope)
* token_expires_at, returns datetime
* token_expired?, true if token expired
* token_issued_at, returns datetime
* service_catalog, returns an array of hashes (services)
* has_service?(type), returns true if service_catalog contains the given type
* roles, returns an array of hashes
* has_role?(name), returns true if user has the given role
* admin?, true if user is a superuser (can do anything)    
* default_services_region, returns the first endpoint region for first non-identity service in the service catalog
* available_services_regions, returns list of unique region name values found in service catalog 


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