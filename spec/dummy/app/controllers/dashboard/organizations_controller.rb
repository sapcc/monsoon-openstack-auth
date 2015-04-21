module Dashboard
  class OrganizationsController < DashboardController
    authorization_actions_for :get_org, :only => [:show]
    authorization_actions :show => 'list'
    before_filter do
      @service = KeystoneService.new(@region)
    end
    
    def index
      @organizations = @service.user_domains(current_user.id)
    end
  
    def show
      @organization = @service.domain(@organization_id)
      @projects = @service.domain_projects(@organization_id, current_user.id)
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

