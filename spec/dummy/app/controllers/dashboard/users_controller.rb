class Dashboard::UsersController < DashboardController
  skip_before_filter :check_terms_of_use
  
  def terms
  end

  def register
    if params[:terms_of_use]
      domain_id = @domain_id || current_user.user_domain_id || current_user.domain_id
      technical_user = TechnicalUser.new(auth_session,domain_id)
      sandbox = technical_user.create_user_sandbox
      redirect_to domain_project_path(@region,domain_id,sandbox.id) and return if sandbox
    end
    
    render action: :terms
  end
end
