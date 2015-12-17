module MonsoonOpenstackAuth
  module Authentication
    class SessionStore
      SESSION_NAME = :monsoon_openstack_auth_token
    
      def initialize(session)
        @session = session
      end
      
      def user_id
        ((self.token || {})["user"] || {})["id"]
      end
    
      def token_presented?
        not @session[SESSION_NAME].nil?
      end
  
      def token_valid?
        token_presented? and 
        @session[SESSION_NAME][:expires_at] and 
        DateTime.parse(@session[SESSION_NAME][:expires_at]) > Time.now
      end
  
      def token_eql?(auth_token)
        @session[SESSION_NAME][:value]==auth_token
      end
    
      def token
        @session[SESSION_NAME]
      end
    
      def token=(token)
        @session[SESSION_NAME]=token
      end
    
      def delete_token
        @session.delete SESSION_NAME
      end
    
      def redirect_to=(url)
        @session[:redirect_to]=url
      end
    
      def redirect_to
        @session[:redirect_to]
      end
    
      def region=(region)
        @session[:region]=region
      end
    
      def region
        @session[:region]
      end
      
      def delete_redirect_to
        @session.delete :redirect_to
      end
    
      def delete_region
        @session.delete :region
      end
    end
  end
end