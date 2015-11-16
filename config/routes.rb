MonsoonOpenstackAuth::Engine.routes.draw do

  resources :sessions, only: [:create]

  get 'sessions(/:domain_id)/new' => 'sessions#new', as: :new_session
  get 'login(/:domain_id)' => 'sessions#new', as: :login
  get 'logout', to: 'sessions#destroy'
end
