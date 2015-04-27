class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  
  def get_region
    @region = params[:region_id]
  end
  
  def authorization_forbidden(error)
    render template: '/layouts/forbidden'
  end
end
