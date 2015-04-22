module MonsoonOpenstackAuth
  module Authorization
    class SecurityViolation < StandardError
      attr_reader :user, :action, :resource

      def initialize(user, action, resource)
        @user     = user
        @action   = action
        @resource = resource
      end

      def message
        "#{@user.name} is not authorized for action #{@action}  on resource: #{@resource}"
      end
    end
    
    class PolicyFileNotFound < StandardError; end
    class PolicyParseError < StandardError; end
    
    class RuleExecutionError < StandardError
      def initialize(rule,locals,params,origin_error=nil)
        @rule = rule
        @locals = locals
        @params = @params
        @origin_error = origin_error
      end
      
      def message
        m = "rule name: #{@rule.name} \n"
        m += "rule: #{@rule.rule} \n"
        m += "parsed rule: #{@rule.parsed_rule} \n"
        m += "required_locals: #{@rule.required_locals} \n"
        m += "required_params: #{@rule.required_params} \n"
        m += "given locals: #{@locals} \n"
        m += "given params: #{@params} \n"
        
        if @origin_error
          m += @origin_error.message
          m += @origin_error.backtrace.join("\n") 
        end
        m
      end
    end
  end
end