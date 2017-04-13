class DashboardController < ApplicationController
  authentication_required project: :get_project, domain: :get_domain, two_factor: :two_factor

  prepend_before_filter do
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end

  def index

  end

  def two_factor_test

  end

  def get_domain
    @domain_id ||= (controller_name == 'domains') ? params[:id] : params[:domain_id]
  end

  def get_project
    @project_id ||= (controller_name == 'projects') ? params[:id] : params[:project_id]
  end

  def two_factor
    action_name=='two_factor_test'
  end
end
