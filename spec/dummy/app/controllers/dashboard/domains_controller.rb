module Dashboard
  class DomainsController < DashboardController
    #authorization_actions_for :Domain, except: [:index] # index not possible because unscoped at this time
    authorization_actions :show => 'show', :index => 'list', :update => 'change', :destroy => 'delete'
    before_filter :load_and_authorize_domain, :except => [:index]

    def index
      @domains = services.identity.user_domains
    end

    def show
      @domain = services.identity.user_domain(@domain_id)
      @projects = services.identity.user_domain_projects(@domain_id)
    end

    def update
      @domain = services.identity.user_domain(@domain_id)
      @projects = services.identity.user_domain_projects(@domain_id)
    end

    def destroy
      @domain = services.identity.user_domain(@domain_id)
      @projects = services.identity.user_domain_projects(@domain_id)
    end

    private

    def load_and_authorize_domain
      domain = Domain.new
      domain.id = @domain_id
      authorization_action_for domain
    end
  end
end

class Domain
  attr_accessor :id
end

