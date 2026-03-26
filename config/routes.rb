Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post "auth/login", to: "auth#login"
      delete "auth/logout", to: "auth#logout"

      resources :test_plans, only: [ :index, :show, :create, :update, :destroy ] do
        resources :test_scenarios, only: [ :create, :update, :destroy ] do
          resources :screenshots, only: [ :create ]
        end
      end

      resources :bugs, only: [ :index, :show, :create, :update, :destroy ]
      resources :tags, only: [ :index ]
    end
  end

  resource :locale, only: :update
  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resources :users, except: [ :show ]

  get "tags/autocomplete", to: "tags#autocomplete"

  root "test_plans#index"

  get "bugs/root_causes", to: "bugs/root_causes#index", as: :bug_root_causes
  get "bugs/tag_suggestions", to: "bugs#tag_suggestions", as: :bug_tag_suggestions
  resources :bugs do
    resource :report, only: :show, controller: "bugs/reports"
  end

  resources :test_plans do
    resource :ai_generation, only: :create, controller: "test_plans/ai_generations"
    resource :report, only: :show, controller: "test_plans/reports"
    resource :scenario_order, only: :update, controller: "test_plans/scenario_orders"
    resources :test_scenarios, only: [ :create, :update, :destroy ] do
      resource :status, only: :update, controller: "test_scenarios/statuses"
    end
  end
end
