MonsoonOpenstackAuth::Engine.routes.draw do
  scope '/regions' do
    scope ':region_id' do
      resources :sessions, only: [:new,:create]
    end
  end
    
  get 'logout', to: 'sessions#destroy'
end
