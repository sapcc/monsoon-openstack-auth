Monsoon Openstack Auth
======================

Implements the authentication functionality using Keystone API.

[![Build Status](https://travis-ci.mo.sap.corp/monsoon/monsoon-openstack-auth.svg?token=zmx4pwNHg8RYRGSuWuM2&branch=authorization)](https://travis-ci.mo.sap.corp/monsoon/monsoon-openstack-auth)

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

  ############# Authentication ################
  # connection driver, default MonsoonOpenstackAuth::Driver::Default (Fog)
  # config.connection_driver = DriverClass
  
  # api auth endpoint
  config.connection_driver.api_endpoint = ENV['MONSOON_OPENSTACK_AUTH_API_ENDPOINT']
  # api admin user
  config.connection_driver.api_userid   = ENV['MONSOON_OPENSTACK_AUTH_API_USERID']
  # api admin password
  config.connection_driver.api_password = ENV['MONSOON_OPENSTACK_AUTH_API_PASSWORD']
  
  # optional, default=true
  config.token_auth_allowed = true
  # optional, default=true
  config.basic_auth_allowed = true
  # optional, default=true
  config.sso_auth_allowed   = true
  # optional, default=true
  config.form_auth_allowed  = true
  
  # optional, default= last url before redirected to form
  #config.login_redirect_url = '/'
  
  ########## Authorization #########  
  # path to policy file
  config.authorization.policy_file_path = "config/policy.json"
  
  # context, default is name of main app, e.g. dashboard. 
  # If you overwrite context so the rules in policy file should begin with that context. 
  # config.authorization.context = "identity"
  
  # action mapping. Default: {
  #        :index   => 'read',
  #        :show    => 'read',
  #        :new     => 'create',
  #        :create  => 'create',
  #        :edit    => 'update',
  #        :update  => 'update',
  #        :destroy => 'delete'
  #    }
  # controller_action_map = {index: 'list'}
  
  # optional, error handler is a controller method which is called on MonsoonOpenstackAuth::Authorization::SecurityViolation. 
  # Default is :authorization_forbidden.
  # You can specify another handler or overwrite "authorization_forbidden" method in controller.
  # security_violation_handler = :authorization_forbidden
  
  ########## Plugin ##########
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

### Authentication

#### Controller

##### authentication_required

##### skip_authorization

Class method which is called in controllers. 
```ruby
authentication_required options
```
options:

* **region**, required. Example: 'europe'
* **organization**, optional. Example: 'o-ghghad'
* **project**, optional. Example: 'p-jhjhhj'
* **only**, optional. Example only: [:index,:show]
* **except**, optional. Example except: [:index,:show]
* **if**, optional. Example if: -> c {c.params[:region_id].nil?}
* **unless**, optional

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

Example: https://github.com/sapcc/monsoon/monsoon-openstack-auth/blob/master/spec/dummy/app/controllers/dashboard_controller.rb

##### skip_authentication

Class method which is called in controllers.
```ruby
skip_authentication options
```
options:

* **only**, optional. Example only: [:index,:show]
* **except**, optional. Example except: [:index,:show]
* **if**, optional. Example if: -> c {c.params[:region_id].nil?}
* **unless**, optional


##### current_user

Instance method, available in controller instances and views. Returns current logged in user or nil.
```ruby
current_user
```

##### logged_in?

Instance method, available in controller instances and views. Returns true if current logged in user is presented.
```ruby
logged_in?
```

#### User Class (current_user)

Instance methods:

* **context**, returns the token received by API
* **enabled?**, true if user is active (enabled)
* **token**, returns the token value (auth_token)  
* **id**, user id (obtained through the token)
* **name**, user name (obtained through the token)
* **description**, user description (obtained through the token)
* **user_domain_id**, received by scoped token
* **user_domain_name**, received by scoped token
* **domain_id**, scope (obtained through the token)
* **domain_name**, scope (obtained through the token)
* **project_id**, scope (obtained through the token)
* **project_name**, scope (obtained through the token)
* **project_domain_id**, scope (obtained through the token)
* **project_domain_name**, scope (obtained through the token)
* **project_scoped**, returns a hash (scope)
* **domain_scoped**, returns a hash (scope)
* **token_expires_at**, returns datetime
* **token_expired?**, true if token expired
* **token_issued_at**, returns datetime
* **service_catalog**, returns an array of hashes (services)
* **has_service?(type)**, returns true if service_catalog contains the given type
* **roles**, returns an array of hashes
* **role_names**, returns an array of roles
* **has_role?(name)**, returns true if user has the given role
* **admin?**, true if user is a superuser (can do anything)    
* **default_services_region**, returns the first endpoint region for first non-identity service in the service catalog
* **available_services_regions**, returns list of unique region name values found in service catalog 


### Authorization

#### Controller


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
