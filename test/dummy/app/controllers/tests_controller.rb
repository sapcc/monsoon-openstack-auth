class TestsController < ApplicationController

  before_filter do
    @region = 'us'
  end
  
  authentication_required only: [:new], region: :get_region, project: :get_project, organization: :get_organization 
  authentication_required only: [:index], region: -> c { 'europe' }, organization: -> c {'Test'}   
  
  def index
    
  end
  
  def new
  end
  
  def get_region
    'us'
  end
  
  def get_organization
    'C5203501'
  end
end
