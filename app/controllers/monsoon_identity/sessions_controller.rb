require_dependency "monsoon_identity/application_controller"

module MonsoonIdentity
  class SessionsController < ApplicationController
    def new
      logout_user
    end
  
    def create
      success = false
      begin
        token = keystone_authenticate(params[:username],params[:password])
        login_user_token(token)
        success = (not current_user.nil?)
      rescue
        p "Session Creation Failed"
      end
    
      if success
        redirect_to root_path
      else
        render action: :new and return 
      end
    end
  
    def destroy
      logout_user
      redirect_to main_app.root_path, :notice => "Signed out!"
    end
  end
end
