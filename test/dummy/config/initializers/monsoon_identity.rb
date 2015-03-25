# API_AUTH_ENDPOINT = 'http://localhost:8183/v3/auth/tokens'
# API_USER_ID       = 'u-admin'
# API_PASSWORD      = 'secret'

# API_AUTH_ENDPOINT = 'http://localhost:5000/v3/auth/tokens'
# API_USER_ID       = '8d5732a0ebd9485396351d74e24c9647'
# API_PASSWORD      = 'openstack'
# END

MonsoonIdentity.configure do |config|
  # config.api_endpoint = 'http://localhost:8183/v3/auth/tokens'
  # config.api_userid   = 'u-admin'
  # config.api_password = 'secret'
  
  # required
  config.api_endpoint = 'http://localhost:5000/v3/auth/tokens'
  config.api_userid   = '8d5732a0ebd9485396351d74e24c9647'
  config.api_password = 'openstack'
  
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
  config.debug=true
end