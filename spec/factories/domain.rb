FactoryGirl.define do
  factory :domain, class: OpenStruct do

    initialize_with { new(domain_id: 'domain_no_id') }

    trait :member_domain do
      after(:stub) do |domain|
        domain[:domain_id] = 'domain_123'
      end
    end

  end
end
