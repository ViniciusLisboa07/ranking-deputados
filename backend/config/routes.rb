Rails.application.routes.draw do
  get "uploads/create"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # API routes namespace - colocar ANTES do root
  namespace :api do
    get "rankings/index"
    get "despesas/index"
    get "despesas/show"
    get "deputados/index"
    get "deputados/show"
    namespace :v1 do
      # Test endpoint
      get "status", to: proc { |env| [200, { "Content-Type" => "application/json" }, [{ message: "Ranking Deputados API funcionando!", status: "ok", timestamp: Time.current, version: "1.0" }.to_json]] }
    end
  end

  # Simple test endpoint for API root
  root to: proc { |env| [200, { "Content-Type" => "application/json" }, [{ message: "Ranking Deputados API funcionando!", status: "ok", timestamp: Time.current }.to_json]] }

  # Defines the root path route ("/")
  # root "posts#index"
end
