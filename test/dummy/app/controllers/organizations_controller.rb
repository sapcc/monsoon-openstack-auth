class OrganizationsController < ApplicationController
  authentication_required only: [:index, :show], region: :get_region, project: :get_project, organization: :get_organization 
  
  def index
    @domains = current_user.domains(@region)
  end
  
  def show
    @domain = current_user.domain(@region,@organization_id)
  end
  
  def get_organization
    @organization_id = params[:id]
  end
end
