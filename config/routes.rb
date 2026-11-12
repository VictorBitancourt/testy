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
  resource :settings, only: [ :edit, :update ]
  resources :evidence_captions, only: :update

  get "tags/autocomplete", to: "tags#autocomplete"

  root "projects#index"
  resources :projects

  get "bugs/root_causes", to: "bugs/root_causes#index", as: :bug_root_causes
  post "bugs/root_causes/ai_analysis", to: "bugs/ai_analyses#create", as: :bug_ai_analysis
  get "bugs/root_causes/ai_analyses/:id", to: "bugs/ai_analyses#show", as: :bug_ai_analysis_report
  post "bugs/ai_draft", to: "bugs/ai_drafts#create", as: :bug_ai_draft
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
