module Dashboard
  class ProjectsController < DashboardController
    before_filter do
      @service = KeystoneService.new(@region)
    end
    
    def show
      @project = @service.project(@project_id)
    end
  end
end
