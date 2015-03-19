class ProjectsController < ApplicationController
  authentication_required only: [:index, :new], region: :get_region, project: :get_project, organization: :get_organization 
  
  def index
    
  end
  
  def new
  end
  
  def get_organization
    @organization_id = params[:organization_id]
  end
  
  def get_project
    @project_id = params[:id]
  end
end
