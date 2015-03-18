Rails.application.routes.draw do

  get 'welcome/index'
  get 'tests/index'
  get 'tests/new'

  mount MonsoonIdentity::Engine => "/monsoon_identity"#, as: :monsoon_identity
  
  root to: 'welcome#index'
end
