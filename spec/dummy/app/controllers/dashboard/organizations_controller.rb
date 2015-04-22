module Dashboard
  class OrganizationsController < DashboardController
    # before_filter do
    #   @service = KeystoneService.new(@region)
    # end
    
    def index
      @organizations = services.identity.user_domains
    end
  
    def show
      @organization = services.identity.domain(@organization_id)
      @projects = services.identity.domain_projects(@organization_id)
    end
  end
end
