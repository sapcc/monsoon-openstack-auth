module Dashboard
  class ProjectsController < DashboardController
    authorization_actions_for :only => [:show]

    def show
      @project = services.identity.project(@project_id)
    end
  end
end
