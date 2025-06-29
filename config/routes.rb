Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Simple test endpoint
  get "/", to: proc { |env| [200, { "Content-Type" => "application/json" }, [{ message: "Ranking Deputados API funcionando!", status: "ok" }.to_json]] }

  # API routes namespace
  namespace :api do
    namespace :v1 do
      # Future endpoints will be added here
    end
  end
end 