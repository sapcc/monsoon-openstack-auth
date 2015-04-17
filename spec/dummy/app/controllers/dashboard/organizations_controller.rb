module Dashboard
  class OrganizationsController < DashboardController
    before_filter do
      @service = KeystoneService.new(@region)
    end
    
    def index
      @organizations = @service.user_domains(current_user.id)
    end
  
    def show
      @organization = @service.domain(@organization_id)
      @projects = @service.domain_projects(@organization_id)
    end
  end
end
