module Dashboard
  class OrganizationsController < DashboardController
    authorization_actions_for :Domain, except: [:index] # index not possible because unscoped at this time
    authorization_actions :show => 'show', :index => 'list', :update => 'change', :destroy => 'delete'
    before_filter :load_and_authorize_domain, :except => [:index]

    def index
      @organizations = services.identity.user_domains
    end

    def show
      @organization = services.identity.user_domain(@organization_id)
      @projects = services.identity.user_domain_projects(@organization_id)

      #@projects = services.identity.projects
      #@projects = @projects.keep_if { |project| current_user.is_allowed?("identity:project_xshow", project: OpenStruct.new({domain_id: project.domain_id})) }
    end

    def update
      @organization = services.identity.user_domain(@organization_id)
      @projects = services.identity.user_domain_projects(@organization_id)
    end

    def destroy
      @organization = services.identity.user_domain(@organization_id)
      @projects = services.identity.user_domain_projects(@organization_id)
    end

    private

    def load_and_authorize_domain
      @domain = Domain.new
      @domain.id = @organization_id
      authorization_action_for @domain
    end
  end
end

class Domain
  attr_accessor :id
end

