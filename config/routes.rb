Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resources :users, except: [:show]

  get "tags/autocomplete", to: "tags#autocomplete"

  root "test_plans#index"

  resources :test_plans do
    resource :ai_generation, only: :create, controller: "test_plans/ai_generations"
    resource :report, only: :show, controller: "test_plans/reports"
    resource :scenario_order, only: :update, controller: "test_plans/scenario_orders"
    resources :test_scenarios, only: [ :create, :update, :destroy ] do
      resource :status, only: :update, controller: "test_scenarios/statuses"
    end
  end
end
