MonsoonIdentity.configure do |conf|
  conf.api_endpoint = 'http://localhost:8183/v3/auth/tokens'
  conf.api_userid   = 'u-admin'
  conf.api_password = 'secret'
end