class DashboardController < ApplicationController
  authentication_required region: :get_region, project: :get_project, organization: :get_organization
  #example: authentication_required only: [:index], region: -> c { 'europe' }, organization: -> c {'Test'}
  
  def index
  end
  
  def get_region
    @region = params[:region_id]
  end
  
  def get_organization
    @organization_id = (controller_name == 'organizations') ? params[:id] : params[:organization_id]
  end
  
  def get_project
    @project_id = (controller_name == 'projects') ? params[:id] : params[:project_id]
  end
end
