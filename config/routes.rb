Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resources :users, except: [:show]

  get "tags/autocomplete", to: "tags#autocomplete"

  root "test_plans#index"

  resources :test_plans do
    member do
      get :report
    end
    resources :test_scenarios, only: [ :create, :update, :destroy ] do
      member do
        patch :update_status
      end
      collection do
        patch :reorder
      end
    end
  end
end
