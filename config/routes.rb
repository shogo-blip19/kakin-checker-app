Rails.application.routes.draw do
  root "top#index"

  resources :users, only: %i[new create]

  get "up" => "rails/health#show", as: :rails_health_check

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "home", to: "home#index"
end
