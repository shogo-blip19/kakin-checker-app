Rails.application.routes.draw do
  root "top#index"

  resources :users, only: %i[new create]

  resources :pays, only: %i[index new create edit update destroy]

  resources :archives, only: :index

  resource :budget, only: %i[new create edit update destroy]

  get "up" => "rails/health#show", as: :rails_health_check


  get "login", to: "sessions#new"
  post "login", to: "sessions#create"


  delete "logout", to: "sessions#destroy"


  get "home", to: "home#index"
end
