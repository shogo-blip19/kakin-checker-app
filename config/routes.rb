Rails.application.routes.draw do
  root "top#index"

  resources :users, only: %i[new create]


  get "up" => "rails/health#show", as: :rails_health_check
end
