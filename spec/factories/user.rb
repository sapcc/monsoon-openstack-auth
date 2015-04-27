FactoryGirl.define do
  factory :user, class: MonsoonOpenstackAuth::User do

    token = ApiStub.keystone_token
    region = 'europe'
    initialize_with { new(region,token) }

    trait :admin do
      after(:stub) do |user|
        user.stub(:admin?).and_return true
        user.stub(:roles).and_return [{id:'r-admin', name:'admin'}]
        user.stub(:project_id).and_return nil
        user.stub(:domain_id).and_return nil
      end
    end

    trait :member do
      after(:stub) do |user|
        user.stub(:admin?).and_return false
        user.stub(:roles).and_return [{id:'r-member',name:'member'}]
        user.stub(:project_id).and_return 'project_123'
        user.stub(:domain_id).and_return 'domain_123'
      end
    end

    trait :neither_admin_nor_member do
      after(:stub) do |user|
        user.stub(:admin?).and_return false
        user.stub(:roles).and_return nil
        user.stub(:project_id).and_return nil
        user.stub(:domain_id).and_return nil
      end
    end
  end
end
