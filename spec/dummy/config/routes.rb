Rails.application.routes.draw do

  mount MonsoonOpenstackAuth::Engine => '/auth'
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
  
  root to: 'welcome#index'
end
