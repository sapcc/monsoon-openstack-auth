module Dashboard
  class OrganizationsController < DashboardController
    before_filter :load_and_authorize_domain, :only => [:show]
    authorization_actions :show => 'show', :index => 'list'

    def index
      @organizations = services.identity.user_domains
    end
  
    def show
      @organization = services.identity.domain(@organization_id)
      @projects = services.identity.domain_projects(@organization_id)
    end

    private

    def load_and_authorize_domain
      @domain = Domain.new
      @domain.id = params[:id]
      authorize_action_for @domain
    end
  end
end

class Domain
  attr_accessor :id
end

