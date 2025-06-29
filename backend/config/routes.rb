Rails.application.routes.draw do
  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    # Upload endpoints
    post "uploads", to: "uploads#create"
    get "uploads/status", to: "uploads#status"

    # Deputados endpoints
    resources :deputados, only: [:index, :show] do
      collection do
        get :statistics
      end
    end

    # Despesas endpoints  
    resources :despesas, only: [:index, :show] do
      collection do
        get :summary
      end
    end

    # Rankings endpoints
    resources :rankings, only: [:index] do
      collection do
        get :gastos_totais
        get :por_categoria
        get :por_estado
        get :por_partido
        get :eficiencia_gastos
        get :comparativo_temporal
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
