require 'json'
require 'singleton'

module MonsoonOpenstackAuth
  class Policy
    include Singleton

    DEFAULT_RULE = 'default'

    attr_accessor :policy_hash, :rules, :rules_src, :debug

    def initialize
      @debug = MonsoonOpenstackAuth.configuration.debug
      load(MonsoonOpenstackAuth.configuration.authorization_policy_file)
    end

    def load file_path
      file = File.read(file_path)
      @policy_hash = JSON.parse(file, symbolize_names: false)
      parse_rules
    end

    def parse_rules
      @rules = {}
      @rules_src = {}
      @policy_hash.each do |rule_name, rule_json|
        begin
          rule = rule_json.gsub(/^$/, 'true') # empty string is always true
          rule = rule.gsub(/True/i, 'true') # normalize true
          rule = rule.gsub(/False/i, 'false') # normalize false
          rule = rule.gsub(/\bor\b/i, 'or') # normalize or
          rule = rule.gsub(/\band\b/i, 'and') # normalize and
          rule = rule.gsub(/%\((?<param>[^\)]+)\)s/, '%(params["\k<param>".to_sym])s')
          rule = rule.gsub(/params\["target\.(?<target>.+)".to_sym\]/, 'params["target".to_sym].\k<target>')
          rule = rule.gsub(/rule:(?<rule>[^\s]+)/, 'locals["rules"]["\k<rule>"].call(locals,params||{})')
          rule = rule.gsub(/role:(?<role>[^\s]+)/, 'locals["roles"].include?("\k<role>")')
          rule = rule.gsub(/(?<key>[^:|\s]+):(?<value>[^\s]+)/, 'locals["\k<key>"]==\k<value>')
          rule = rule.gsub(/%\(/, '').gsub(/\)s/, '')

          @rules[rule_name] = Rule.new(rule) #eval("-> locals,params { #{rule} }"))
          @rules_src[rule_name] = rule if @debug
        rescue => e
          raise e
        end
      end
    end

    def enforce current_user, actions, params={}
      chk = Check.new(@rules, @roles, current_user, @rules_src, @debug)
      check_result = chk.enforce(actions, params)
      unless check_result.result
        raise SecurityViolation.new(current_user, actions, params)
      end
      check_result.result
    end

    class Rule
      attr_accessor :rule, :rule_src

      def initialize rule
        @rule_src = rule
        @rule = eval("-> locals,params { #{rule} }")
      end

      def call locals, params
        @rule.call(locals, params)
      end

      def method_missing(m, *args, &block)
        puts "There's no method called #{m} here -- please try again."
      end

    end

    class Check

      def initialize(rules, roles, current_user, rules_src, debug=false)
        @current_user = current_user
        @rules = rules
        @rules_src = rules_src
        @debug = debug
      end

      def enforce(check_rules, params={})
        locals = {
            'rules' => @rules,
            'roles' => @current_user.roles||[],
            'domain_id' => @current_user.domain_id,
            'is_admin' => @current_user.admin?,
            'project_id' => @current_user.project_id,
            'user_id' => @current_user.id
        }
        res = false
        src = "no debug"
        check_rules.each do |k|
          begin
            if @debug
              src = "#{@rules_src[k]}"
            end
            res |= @rules[k].call(locals, params) # @rules[k].call(locals, params)
          rescue NoMethodError => nme
            # Exception happens when a NON existent rule is checked
            # Use default rule if available, otherwise false
            if nme.message.match(/^undefined method `call'/)
              default_rule = @rules[DEFAULT_RULE]
              if default_rule
                res |= default_rule.call(locals, params) #call(locals, params)
              else
                res |= false
              end
            # Exception happens when rules contains target params which aren't passed to check
            elsif nme.message.match(/^undefined method.*for nil:NilClass/)
              res |= false
            end
          rescue NameError => ne
            raise PolicyInvalid.new "Undefined object in rule \"#{k}\" which processes #{src}. #{ne.message}"
          rescue Exception => e
            raise PolicyInvalid.new "Undefined object in rule \"#{k}\" which processes #{src}. #{e.message}"
          end
        end
        PolicyCheckResult.new res, src
        #res
      end
    end
  end

  class PolicyCheckResult
    attr_reader :result, :source

    def initialize result, source
      @result = result
      @source = source
    end
  end

  class PolicyInvalid < StandardError

  end

end