Rails.application.routes.draw do
  # Liveness: 200 if the app boots, no database access.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      post "auth/login", to: "sessions#create"
      delete "auth/logout", to: "sessions#destroy"
      get "me", to: "sessions#show"

      get "meta", to: "meta#show"
      get "dashboard", to: "dashboard#show"
      get "reports", to: "reports#show"
      resources :macros, only: :index

      get "help/articles", to: "help#articles"
      get "help/articles/:id", to: "help#article"
      post "help/requests", to: "help#create_request"

      resources :customers, only: %i[index show]

      resources :tickets, only: %i[index show create update] do
        member do
          post :resolve
          post :reopen
          post :apply_macro
          post :merge
          post :link
          post :csat
          post :triage, to: "ai#triage"
          post "triage/apply", to: "ai#apply_triage"
          post :prepare_resolution, to: "ai#prepare_ticket_resolution"
        end
        collection do
          post :bulk_update
        end
        resources :messages, only: :create, controller: "ticket_messages"
        resources :articles, only: %i[create destroy], controller: "ticket_articles"
      end

      resources :articles, only: %i[index show create update] do
        member do
          post :publish
          post :unpublish
        end
      end

      resources :incidents, only: %i[index show] do
        member do
          post :confirm
          post :dismiss
          post :resolve
          post :prepare_resolution, to: "ai#prepare_incident_resolution"
          post :apply_resolution
        end
        resources :tickets, only: %i[create destroy], controller: "incident_tickets"
      end

      post "ai/pattern_scan", to: "ai#pattern_scan"
      resources :agent_runs, only: %i[index show]
      resources :audit_logs, only: :index

      post "admin/demo_reset", to: "admin#demo_reset"
    end
  end
end
