MonsoonOpenstackAuth::Engine.routes.draw do
  resources :sessions, only: [:new,:create]
      
  get 'logout', to: 'sessions#destroy'
end
