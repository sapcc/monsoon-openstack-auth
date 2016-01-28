MonsoonOpenstackAuth.configure do |config|
  # connection driver, default MonsoonOpenstackAuth::Driver::Default (Fog)
  # config.connection_driver = DriverClass
  config.connection_driver.api_endpoint = Rails.application.config.keystone_endpoint
  
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
    
  config.provide_sso_domain = true
  
  # optional, default= last url before redirected to form
  #config.login_redirect_url = '/'
  
  # optional, default=false
  config.debug=true

  # authorization policy file
  config.authorization.policy_file_path = "config/policy_test.json"
  config.authorization.context = "identity"
end
