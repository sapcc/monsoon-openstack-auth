Rails.application.routes.draw do

  mount MonsoonOpenstackAuth::Engine => '/auth'
  get 'welcome/index'

  resources :dashboard, only: [:index] do
    get 'two_factor_test', on: :collection  
  end
  get 'policy/show'

  root to: 'welcome#index'
end
