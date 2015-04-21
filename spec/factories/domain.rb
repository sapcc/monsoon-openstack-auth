FactoryGirl.define do
  class Domain
    attr_accessor :id
  end

  factory :domain, class: Domain do

    id 'domain_no_id'

    trait :member_domain do
      after(:stub) do |domain|
        domain.id = 'domain_123'
      end
    end

  end
end
