module MonsoonOpenstackAuth
  module Authentication
    class AuthDefaultDomain
      attr_accessor :id, :name, :enabled, :description
      def initialize(params={})
        @id           = params[:id]
        @name         = params[:name]
        @description  = params[:description]
        @enabled      = params[:enabled]
      end  
    end
  end
end