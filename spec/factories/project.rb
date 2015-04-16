FactoryGirl.define do
  factory :project, class: OpenStruct do

    initialize_with { new(project_id: 'project_no_id') }

    trait :member_project do
      after(:stub) do |project|
        project[:project_id] = 'project_123'
      end
    end

  end
end
