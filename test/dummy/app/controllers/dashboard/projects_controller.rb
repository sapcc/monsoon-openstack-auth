module Dashboard
  class ProjectsController < DashboardController
    before_filter do
      @service = KeystoneService.new(MonsoonIdentity::Auth.keystone_connection(@region))
    end
    
    def show
      @project = @service.project(@project_id)
    end
  end
end
