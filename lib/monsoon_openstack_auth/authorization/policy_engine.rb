require 'json'
require 'singleton'

module MonsoonOpenstackAuth
  module Authorization
    class PolicyEngine
      
      DEFAULT_RULE_NAME = 'default'
    
      def initialize(policy_json)
        @rules            = RulesContainer.new
        @parsed_policy    = {}
        @required_locals  = []
        parse_rules(policy_json)
      end
      
      def policy(current_user)
        Policy.new(@rules,current_user)
      end

      protected
      
      def parse_rules(policy_json)
        begin 
          policy_hash = JSON.parse(policy_json)
          policy_hash.each do |name, rule|
            parsed_rule = Rule.parse(@rules,name,rule)
            @rules.add(name, parsed_rule)
            @parsed_policy[name] = Rule.parse(@rules,name,rule)
            @required_locals += parsed_rule.required_locals
          end
          
        rescue => e
          raise PolicyParseError.new("Could not parse policy json #{e}")
        end
      
        @required_locals = @required_locals.uniq
        unsupported_locals = (@required_locals.uniq - Policy::LOCALS.keys)
        # policy contains unsupported variable names
        if unsupported_locals.length > 0
          raise PolicyParseError.new("Policy contains unsupported variable names #{unsupported_locals}")
        end
      
      end
      
      class RulesContainer
        def initialize
          @hash = Hash.new
        end
        
        def add(name,rule)
          @hash[name]=rule
        end
        
        def get(name)
          # Return default rule unless the requested rule name is presented. 
          # Default rule can be defined in policy file or the default rule from Rule is used. 
          # The Rule.default_rule returns false on execute.
          (@hash[name] || @hash[DEFAULT_RULE_NAME] || Rule.default_rule)
        end
        
        delegate :each, to: :@hash   
      end

      class Policy
        LOCALS = {
          'roles'       => lambda { |current_user| current_user.roles||[] } ,
          'domain_id'   => lambda { |current_user| current_user.domain_id },
          'is_admin'    => lambda { |current_user| current_user.admin? },
          'project_id'  => lambda { |current_user| current_user.project_id },
          'user_id'     => lambda { |current_user| current_user.id }
        }
    
        class << self      
          def locals(current_user)
            result = {}
            LOCALS.each{|name,proc| result[name]=proc.call(current_user)}
            result
          end   
        end
    
        def initialize(rules,current_user)
          @rules = rules
          @locals = Policy.locals(current_user)
        end
    
        def enforce(rule_names=[], params = {})
          result = true
          rule_names = [rule_names] unless rule_names.is_a?(Array)
          rule_names.each do |name|
            result &= @rules.get(name).execute(@locals,params)
          end
          result
        end
      end
      
      class Rule
        attr_reader :name, :rule, :parsed_rule, :required_locals, :required_params
    
        class << self
          def parse(all_rules,name, rule)
            
            ############ normalize rule ############
            # replace %(text)s with params["text"]
            parsed_rule = rule.gsub(/%\(/,'params["').gsub(/\)s/,'"]')
            # replace "(" and ")" with " ( " and " ) "
            parsed_rule = parsed_rule.gsub(/\s*(?<bracket>\(|\))\s*/, ' \k<bracket> ')
            # replace "or" and "and" with " or " and " and "
            parsed_rule = parsed_rule.gsub(/\s+(?<operator>or|\bor\b|and|\band\b)\s+/i, ' \k<operator> ')
            # remove spaces betwenn ":" and text
            parsed_rule = parsed_rule.gsub(/\s*(?<colon>:)\s*/, '\k<colon>')
            ############# end #############
        
            # replace params["param1.param2.param3"] with params["param1"].param2.param3
            parsed_rule = parsed_rule.gsub(/params\["(?<param>[^\.|\]]+)(?<attributes>(\.[^\]]+)+)"\]/,'params["\k<param>"]\k<attributes>')
            # replace params["param"] with params["param".to_sym]
            parsed_rule = parsed_rule.gsub(/params\["(?<param>[^\]]+)"\]/,'params["\k<param>".to_sym]')
            # replace "True" and "@" and empty rule with "true"
            parsed_rule = parsed_rule.gsub(/^$/,'true').gsub(/True|@/i, 'true')
            # replace "False" and "!" with "false"
            parsed_rule = parsed_rule.gsub(/False|!/i, 'false')
            # replace rule:name with @rules["name"].execute(locals,params)
            parsed_rule = parsed_rule.gsub(/rule:(?<rule>[^\s]+)/,'@rules.get("\k<rule>").execute(locals,params)')
            # replace role:name with locals["roles"].include?("name")
            parsed_rule = parsed_rule.gsub(/role:(?<role>[^\s]+)/,'locals["roles"].include?("\k<role>")')
            # replace name:value with locals["name"]=="value"
            parsed_rule = parsed_rule.gsub(/(?<key>[^\s|:]+):(?<value>[^\s]+)/,'locals["\k<key>"]==\k<value>')
        
            self.new(all_rules, name,rule, parsed_rule)
          end
          
          def default_rule
            @default_rule ||= self.new(nil,'default_rule','!','false')
          end
        end
    
        def initialize(all_rules,name,rule,parsed_rule)
          @name             = name
          @rules            = all_rules
          @rule             = rule
          @parsed_rule      = parsed_rule
          @required_locals  = extract_required_locals
          @required_params  = extract_required_params
          @executable       = eval("lambda {|locals={},params={}| #{@parsed_rule} }")
        end
    
        def to_s
          "name: #{@name} \nrule: #{@rule} \nparsed rule: #{@parsed_rule}"
        end

        def execute(locals,params)
          begin
            @executable.call(locals,params)
          rescue NoMethodError => nme
            false
          rescue NameError => ne
            false
          rescue Exception => e
            raise RuleExecutionError.new(self,locals,params,e)
          end
        end
    
        protected

        def extract_required_locals
          @parsed_rule.scan(/locals\["([^\]]+)"\]/).flatten
        end     
    
        def extract_required_params
          @parsed_rule.scan(/params\["([^"]+)".to_sym\]/).flatten
        end
      end
    end
  end
end