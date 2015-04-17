class PolicyController < ApplicationController

  authentication_required only: [:show], region: -> c { 'europe' }, organization: -> c {'localsmkey02'}
  authorization_required

  def show
    @current_user = OpenStruct.new(id: 'user_abc123', admin?: true, domain_id: 'test', project_id: 'project_test', roles: ['noadmin','service'])
    @target = OpenStruct.new(token: OpenStruct.new(user_id: 'user_abc123', project_id: 'project_test', user: OpenStruct.new(domain: OpenStruct.new(id: 'test')), credential: OpenStruct.new(user_id: 'user_abc123')))

#    @policy = MonsoonOpenstackAuth::Policy.new (true)
#    @policy.load("config/policy_ceilometer.json")
#    @policy.load("config/policy_nova.json")
#     @policy.load("config/policy_keystone.json")
#    @policy.load("config/policy_test.json")

    @policy_checks = []

    @policy.rules.each do |k,v|
      @policy_checks << "@policy.for(@current_user).check(['#{k}'],{target:@target.token})"
    end


   #@policy_checks << "@policy.for(@current_user).check(['default_check_should_be_applied'],{})"
   # @policy_checks << "@policy.for(@current_user).check(['service_role'],{})"
   # @policy_checks << "@policy.for(@current_user).check(['context_is_project'],{target:@target.token})"
   # @policy_checks << "@policy.for(@current_user).check(['owner'],@target.token)"

    #
    # <%= "admin_required => #{@policy.for(@current_user).check(['admin_required'],{})}" %>
    # <%= "service_role => #{@policy.for(@current_user).check(['service_role'],{})}" %>
    # <%= "admin_or_owner => #{@policy.for(@current_user).check(['admin_or_owner'],{target:@target})}" %>
    # <%= "admin_or_owner and  service_role and admin_required => #{@policy.for(@current_user).check(['admin_or_owner','service_role','admin_required'],{target:@target})}" %>
    # <%= "admin_or_owner and  admin_required => #{@policy.for(@current_user).check(['admin_or_owner','admin_required'],{target:@target})}" %>
    #
  end
end
