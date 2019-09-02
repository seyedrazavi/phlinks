Rails.application.routes.draw do
  resources :links, except: [:index, :show, :new, :create] do
  	member do
  		get 'fetch'
  	end
  end
  root 'pages#home'
  get 'about', to: 'pages#about', as: 'pages'
  get 'pocket/add', to: 'pocket#add', as: 'pocket_add'
  get 'oauth/callback', to: 'pocket#callback'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
