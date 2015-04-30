module Dashboard
  class ProjectsController < DashboardController
    def show
      @project = services.identity.user_project(@project_id)
      if_allowed?("identity:project_show", {id: @project.id}) do
        @project
      end
    end

    def update
      @project = services.identity.user_project(@project_id)
      if_allowed?("identity:project_change", {id: @project.id}) do
        @project
      end
    end

    def destroy
      @project = services.identity.user_project(@project_id)
      if_allowed?("identity:project_delete", {id: @project.id}) do
        @project
      end
    end
  end
end
