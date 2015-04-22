module Dashboard
  class OrganizationsController < DashboardController
    authorization_actions_for :get_org, :only => [:show]
    authorization_actions :show => 'list'

    def index
      @organizations = services.identity.user_domains
    end
  
    def show
      @organization = services.identity.domain(@organization_id)
      @projects = services.identity.domain_projects(@organization_id)
    end

    private

    def get_org
      domain = Domain.new
      domain.domain_id = "o-7052f82e0"
      return domain
    end
  end
end

class Domain
  attr_accessor :domain_id
end

