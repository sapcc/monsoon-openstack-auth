class DashboardController < ApplicationController
  authentication_required region: :get_region, project: :get_project, domain: :get_domain
  #example: authentication_required only: [:index], region: -> c { 'europe' }, domain: -> c {'Test'}
  include OpenstackServiceProvider::Services
  
  prepend_before_filter do
    @region ||= params[:region_id]
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
  
  before_filter :check_terms_of_use
  
  def index

  end
  
  def get_region
    @region ||= params[:region_id]
  end
  
  def get_domain
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
  end
  
  def get_project
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
  
  protected
  
  def check_terms_of_use
    return unless current_user
    domain_id = @domain_id || current_user.user_domain_id || current_user.domain_id
    
    technical_user = TechnicalUser.new(auth_session,domain_id)

    unless current_user.roles.length>0 or technical_user.sandbox_exists?
      session[:requested_url] = request.env['REQUEST_URI']
      redirect_to terms_of_use_path(get_region)
    end
  end
end
