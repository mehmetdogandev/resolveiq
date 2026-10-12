Rails.application.routes.draw do
  # Liveness: 200 if the app boots, no database access.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"
    end
  end
end
