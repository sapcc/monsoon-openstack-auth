class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  before_filter do 
    begin 
      @service_user = MonsoonOpenstackAuth.api_client(MonsoonOpenstackAuth.configuration.default_region).service_user
      @domains = @service_user.domains.auth_domains
      @monsooncc = @domains.all(domain_name:'monsooncc').first
      @admin_role = @service_user.roles.all(name:'admin').first
    rescue => e
      Rails.logger.error(e.message)
    end

  end
    
  def get_region
    @region = params[:region_id]
  end
  
  def authorization_forbidden(error)
    render template: '/layouts/forbidden'
  end
end
