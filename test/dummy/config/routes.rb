Rails.application.routes.draw do

  get 'welcome/index'
  get 'tests/index'
  get 'tests/new'
  
  scope '/regions' do
    scope ':region_id' do
      resources :organizations, only: [:index, :show] do
        resources :projects, only: [:index, :show]
      end
    end
  end
  
  #resources :organizations, only: [:index, :show]

  mount MonsoonIdentity::Engine => "/monsoon_identity"#, as: :monsoon_identity
  
  root to: 'welcome#index'
end
