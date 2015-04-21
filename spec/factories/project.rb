FactoryGirl.define do

  class Project
    attr_accessor :id
  end

  factory :project, class: Project do

    id 'project_no_id'

    trait :member_project do
      after(:stub) do |project|
        project.id = 'project_123'
      end
    end

  end
end
