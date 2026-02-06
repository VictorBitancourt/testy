Rails.application.routes.draw do
  root 'test_plans#index'
  
  resources :test_plans do
    member do
      get :report
    end
    resources :test_scenarios, only: [:create, :update, :destroy] do
      member do
        patch :update_status
      end
    end
  end
end