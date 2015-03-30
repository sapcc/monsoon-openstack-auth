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

### Develop
```
git clone https://github.com/sapcc/monsoon/monsoon-openstack-auth.git
cd monsoon-openstack-auth
bundle install
cd spec/dummy
bundle exec rake db:migrate
bundle exec rails s
```