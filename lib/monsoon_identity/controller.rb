module MonsoonIdentity
  module Controller
    def self.included(base)
      base.send :extend, ClassMethods
      base.helper_method :current_user, :logged_in?
      base.send :include, MonsoonIdentity::Controller::InstanceMethods
    end
 
    module ClassMethods

      def authentication_required(options={})
        # unless self.ancestors.include?(MonsoonIdentity::Controller::InstanceMethods)
        #   send :include, InstanceMethods
        # end

        reg = options.delete(:region)
        org = options.delete(:organization)
        prj = options.delete(:project)
        
        raise MonsoonIdentity::InvalidRegion.new("An region should be provided") unless reg
              

        before_filter options do
          region = reg.kind_of?(Proc) ? reg.call(self) : self.send(reg.to_sym)
          
          if org
            if org.kind_of?(Proc)
              organization = org.call(self)
            else 
              organization = self.send(org.to_sym) if self.respond_to?(org.to_sym)
            end
          end
          
          if prj
            if prj.kind_of?(Proc)
              project = prj.call(self)
            else 
              project = self.send(prj.to_sym) if self.respond_to?(prj.to_sym)
            end
          end
          @monsoon_identity = MonsoonIdentity::Auth.authenticate(self, region, organization: organization, project: project)
        end
      end
    end
 
    module InstanceMethods
        
      def current_user
        if @monsoon_identity
          @monsoon_identity.user
        else
          MonsoonIdentity::Auth.user_from_session(self)
        end
      end
      
      def logged_in?
        if @monsoon_identity
          @monsoon_identity.logged_in?
        else
          not MonsoonIdentity::Auth.user_from_session(self).nil?
        end
      end
    end
  end
end