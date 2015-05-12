class DashboardController < ApplicationController
  authentication_required region: :get_region, project: :get_project, domain: :get_domain
  #example: authentication_required only: [:index], region: -> c { 'europe' }, domain: -> c {'Test'}
  include OpenstackServiceProvider::Services
  
  def index

  end
  
  def get_region
    @region = params[:region_id]
  end
  
  def get_domain
    @domain_id = (controller_name == 'domains') ? params[:id] : params[:domain_id]
  end
  
  def get_project
    @project_id = (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
end
