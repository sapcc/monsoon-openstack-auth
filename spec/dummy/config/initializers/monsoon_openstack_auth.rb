MonsoonOpenstackAuth.configure do |config|
  p '------------------------------------------'
  p ENV['MONSOON_OPENSTACK_AUTH_API_ENDPOINT']
  p ENV['MONSOON_OPENSTACK_AUTH_API_USERID']
  p ENV['MONSOON_OPENSTACK_AUTH_API_PASSWORD']
  p '##########################################'
  
  config.api_endpoint = ENV['MONSOON_OPENSTACK_AUTH_API_ENDPOINT']
  config.api_userid   = ENV['MONSOON_OPENSTACK_AUTH_API_USERID']
  config.api_password = ENV['MONSOON_OPENSTACK_AUTH_API_PASSWORD']
  
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