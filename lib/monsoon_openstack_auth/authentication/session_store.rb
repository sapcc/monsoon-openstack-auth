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
      
      def token_almost_expired?
        # almost expired means the token expires in less than 5 minutes but after 30 seconds
        if token_presented? and @session[SESSION_NAME][:expires_at]
          rest_time = (DateTime.parse(@session[SESSION_NAME][:expires_at]).to_time-Time.now)/60
          return (rest_time>0.5 and rest_time<5)
        else
          return false
        end
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
    
      def requested_url=(url)
        @session[:monsoon_openstack_auth_requested_url]=url
      end
    
      def requested_url
        @session[:monsoon_openstack_auth_requested_url]
      end
      
      def delete_requested_url
        @session.delete :monsoon_openstack_auth_requested_url
      end
      
      def referer_url=(url)
        @session[:monsoon_openstack_auth_referer_url]=url
      end
    
      def referer_url
        @session[:monsoon_openstack_auth_referer_url]
      end
      
      def delete_referer_url
        @session.delete :monsoon_openstack_auth_referer_url
      end
      
      def redirect_to_callback_id=(callback_id)
        @session[:monsoon_openstack_auth_redirect_to_callback]=callback_id
      end
    
      def redirect_to_callback_id
        @session[:monsoon_openstack_auth_redirect_to_callback]
      end
      
      def delete_redirect_to_callback_id
        @session.delete :monsoon_openstack_auth_redirect_to_callback
      end
    end
  end
end