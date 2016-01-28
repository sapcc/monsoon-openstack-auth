class DashboardController < ApplicationController
  authentication_required project: :get_project, domain: :get_domain

  prepend_before_filter do
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
  
  def index

  end
  
  def get_domain
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
  end
  
  def get_project
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
  
  protected
end
