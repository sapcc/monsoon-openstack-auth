module Dashboard
  class ProjectsController < DashboardController
    before_filter do
      @service = KeystoneService.new(MonsoonOpenstackAuth.api_client(@region))
    end
    
    def show
      @project = @service.project(@project_id)
    end
  end
end
