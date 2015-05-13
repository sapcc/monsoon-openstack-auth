MonsoonOpenstackAuth::Engine.routes.draw do
  scope '(:region_id)' do
    resources :sessions, only: [:new,:create]
  end
      
  get 'logout', to: 'sessions#destroy'
end
