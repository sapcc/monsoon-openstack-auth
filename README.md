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
  config.connection_driver = DriverClass

  # api auth endpoint
  config.connection_driver.api_endpoint = ENV['MONSOON_OPENSTACK_AUTH_API_ENDPOINT']

  # optional, default=true
  config.token_auth_allowed = true
  # optional, default=true
  config.basic_auth_allowed = true
  # optional, default=true
  config.sso_auth_allowed   = true
  # optional, default=true
  config.form_auth_allowed  = true
  # optional, default=false
  config.access_key_auth_allowed = false

  # optional, default= last url before redirected to form
  #config.login_redirect_url = '/'

  ########## Authorization #########  
  # policy_file_path: path to policy file
  config.authorization.policy_file_path = "config/policy.json"

  # context: Default is name of main app, e.g. dashboard.
  # If you overwrite context, rules in policy file should begin with that context.
  config.authorization.context = "identity"

  # controller_action_map: default action mappings for controller actions. Can be overwritten inside controller
  config.authorization.controller_action_map {
       :index   => 'read',
       :show    => 'read',
       :new     => 'create',
       :create  => 'create',
       :edit    => 'update',
       :update  => 'update',
       :destroy => 'delete'
  }
  # config.authorization.security_violation_handler: Error handler method which is called when MonsoonOpenstackAuth::Authorization::SecurityViolation appears.
  # Default setting is  :authorization_forbidden.
  # You can specify another handler or overwrite "authorization_forbidden" method in controller.
  security_violation_handler = :authorization_forbidden

  ########## Plugin ##########
  # optional, default=false
  config.debug=false
  # optional Excon request and response debug, default=false
  config.debug_api_calls=false
end
```

### Session Store
If this gem should support the form based login then the session store must be anything but cookie_store.

Example of setting up a [ActiveRecord session_store](https://github.com/rails/activerecord-session_store)

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

#### ActionController::API

ActionController::API does not include http basic functionality. So you have to include it manually if you want to support http basic. 

```ruby
include ActionController::HttpAuthentication::Basic::ControllerMethods
```

ActionController::API does not include MonsoonOpenstackAuth::Authentication. So you have to include it manually. 

```ruby
include MonsoonOpenstackAuth::Authentication
```


#### Controller

##### authentication_required

Class method which is called in controllers.

```ruby
authentication_required options
```
options:

* **domain**, optional. Example: 'o-ghghad'
* **project**, optional. Example: 'p-jhjhhj'
* **only**, optional. Example only: [:index,:show]
* **except**, optional. Example except: [:index,:show]
* **if**, optional. Example if: -> c {c.params[:region_id].nil?}
* **unless**, optional

Example:

```ruby
DashboardController < ApplicationController
  authentication_required

  def index
  end

end


```ruby
DashboardController < ApplicationController
  authentication_required 

  def index
  end

end
```

Example:

```ruby
DashboardController < ApplicationController
  authentication_required only: [:index], project: :get_project, domain: :get_domain

  def index
  end

  def get_domain
    @domain_id = (controller_name == 'organizations') ? params[:id] : params[:domain_id]
  end

  def get_project
    @project_id = (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
end
```

[Example from Dummy Application](https://github.com/sapcc/monsoon/monsoon-openstack-auth/blob/master/spec/dummy/app/controllers/dashboard_controller.rb)

##### skip_authentication

Class method which is called in controllers.

```ruby
skip_authentication options
```
options:

* **only**, optional. Example only: [:index,:show]
* **except**, optional. Example except: [:index,:show]
* **if**, optional. Example if: -> c {!c.params[:domain].nil?}
* **unless**, optional


##### current_user

Instance method, available in controller instances and views. Returns current logged in user or nil.

```ruby
current_user
```

##### logged_in?

Instance method, available in controller instances and views. Returns true if current logged in user is
presented.

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

Authorization is inspired by the [authority gem from nathanl](https://github.com/nathanl/authority). In contrast to it's origin, authorization uses policy files for
the authorization checks and not authorizer classes.
So you now have to implement a policy file in json format for you application. The file has to be located under `config.authorization.policy_file_path` .

An example could look like:

```json
{
  "default": "rule:admin_required",
  "p_member" : "project_id:%(project.id)s",
  "d_member" : "domain_id:%(domain.id)s",
  "admin_required": "role:admin or is_admin:True",
  "admin_or_project_member": "rule:admin_required or rule:p_member",
  "admin_or_domain_member": "rule:admin_required or rule:d_member",  

  "identity:domain_list":    "rule:test or rule:admin_required or rule:is_service or rule:admin_or_domain_member",
  "identity:domain_show":     "rule:admin_required or rule:d_member",
  "identity:domain_create":   "",
  "identity:domain_change":   "rule:admin_required or rule:d_member",
  "identity:domain_delete":   "rule:admin_required",
  "identity:project_list":    "rule:admin_or_domain_member",
  "identity:project_create":  "rule:admin_or_domain_member",
  "identity:project_change":  "rule:admin_or_domain_member or rule:p_member"
}
```

The policy syntax is described at [openstack olso policies](http://docs.openstack.org/developer/oslo.policy/api.html).

Some explanations on that:

```"default": "rule:admin_required" ``` defines the default rule which is used in case that an authorization request with an undefined rule is made.

```"admin_required": "role:admin or is_admin:True"``` defines a rule which can later be referenced in other rules. It uses the role and is_admin attributes from the current user for whom a authorization request is made.

```"d_member" : "domain_id:%(domain.id)s"``` when the user domain_id from his current authentication scope is the same as the one given to the auth. request. The auth. request could be made with an Domain object which has an id attribute.

```"identity:project_list":    "rule:admin_or_domain_member"``` defines a application specific rule where the context is identity (might come from config.authorization.context) and the action to be checked is project_list.

#### Explizit authorization enforcement

You've to use the policy_engine to do a policy enforcement. The engine is always available

```policy_engine = MonsoonOpenstackAuth.policy_engine```

Afterwards you can do a policy check for a user with

```ruby
action = "identity:project_list"
policy_engine.policy(@current_user).enforce(action)
```
You get a `true or false` as an result.

#### User authorization checks

Similar to the above but more convinient you can check authorizations for a user with the `is_allowed?` method. So you can ask

```ruby
action = "identity:project_list"
@current_user.is_allowed?(action, @domain)
```
and get a boolean response.

#### Controller authorization enforcements

Controllers get some additional class methods for authorization purpose automatically through a railtie.

You can check authorization in your controllers in one of two ways:

`authorization_actions_for ModelClass [, :name => 'ModelNameUsedInPolicy', :actions => {:action_name => 'policy_action_name'}, <StandardBeforeFilterOptions> ]`

protects multiple controller actions with a before_filter, which performs a class-level check. If the current user is never allowed to delete a ModelClass, he'll never even get to the controller's destroy method.

`authorization_action_for @model [, :name => 'ModelNameUsedInPolicy' ]`

can be called inside a single controller action, and performs an instance-level check. If called inside update, it will check whether the current user is allowed to update this particular @model instance.

If either method finds a user attempting something they're not authorized to do, a Security Violation will result.

How does `authorization_actions_for` know to check deletable_by? before the controller's destroy action? It checks your configuration from config.authorization.controller_action_map configured in the initializer file.

The mappings are also configurable per controller with

```ruby
authorization_actions :index => 'list', :update => 'change'
```

Alternatively you can call an authorization check by it's rule directly with an

```ruby
  if_allowed?(PolicyFileRule [, {key: value, ...}])
```

#### User authorization checks

Authorizations for a user can be checked by the `is_allowed?` method. So you can ask

```ruby
@current_user.is_allowed?(PolicyFileRule, params)
```

Example:
```ruby
  @current_user.is_allowed?("identity:project_create", {domain_id: 1})
  @current_user.is_allowed?(["identity:project_create","identity:project_change"], {domain_id: 1})
```


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
