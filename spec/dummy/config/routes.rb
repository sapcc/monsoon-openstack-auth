Rails.application.routes.draw do

  mount MonsoonOpenstackAuth::Engine => '/auth'
  get 'welcome/index'
    
  scope '/regions' do
    scope ':region_id' do
      resources :dashboard, only: [:index]
      
      scope module: 'dashboard' do
        resources :domains, only: [:index, :show, :update, :destroy] do
          resources :projects, only: [:index, :show, :update, :destroy]
        end
      end
    end
  end

  get 'policy/show'

  root to: 'welcome#index'
end
