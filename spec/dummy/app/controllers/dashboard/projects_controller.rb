module Dashboard
  class ProjectsController < DashboardController
    def show
      @project = services.identity.project(@project_id)
    end
  end
end
