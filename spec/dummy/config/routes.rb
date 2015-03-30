Rails.application.routes.draw do

  get 'welcome/index'
    
  scope '/regions' do
    scope ':region_id' do
      resources :dashboard, only: [:index]
      
      scope module: 'dashboard' do
        resources :organizations, only: [:index, :show] do
          resources :projects, only: [:index, :show]
        end
      end
    end
  end
  
  #resources :organizations, only: [:index, :show]

  mount MonsoonIdentity::Engine => "/monsoon_identity"
  
  root to: 'welcome#index'
end
