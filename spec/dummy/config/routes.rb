Rails.application.routes.draw do

  mount MonsoonOpenstackAuth::Engine => '/auth'
  get 'welcome/index'
        
  resources :dashboard, only: [:index]
  get 'policy/show'

  root to: 'welcome#index'
end
