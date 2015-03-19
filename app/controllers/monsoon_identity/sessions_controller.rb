require_dependency "monsoon_identity/application_controller"

module MonsoonIdentity
  class SessionsController < ApplicationController
    def new
      MonsoonIdentity::Auth.logout_user(self)
    end
  
    def create
      redirect_to_url = MonsoonIdentity::Auth.login_form_user(self,params[:username],params[:password])
      if redirect_to_url 
        redirect_to redirect_to_url, notice: 'Signed on!'
      else
        render action: :new
      end
    end
  
    def destroy
      MonsoonIdentity::Auth.logout_user(self)
      redirect_to main_app.root_path, notice: "Signed out!"
    end
  end
end
