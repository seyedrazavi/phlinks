Rails.application.routes.draw do
  resources :links, except: [:index, :show, :new, :create] do
  	member do
  		get 'fetch'
  	end
  end
  root 'pages#home'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
