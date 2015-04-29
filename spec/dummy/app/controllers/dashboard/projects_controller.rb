module Dashboard
  class ProjectsController < DashboardController
    authorization_actions_for :get_project, :only => [:update, :destroy]

    def show
      @project = services.identity.user_project(@project_id)
    end

    def update
      @project = services.identity.user_project(@project_id)
    end

    def destroy
      @project = services.identity.user_project(@project_id)
    end
  end

  def get_project
    @project = Project.new
    @project.id = @project_id
  end
end

class Project
  attr_accessor :id
end
