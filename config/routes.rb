Rails.application.routes.draw do
  post "/auth/register", to: "authentication#register"
  post "/auth/login",    to: "authentication#login"

  resources :tracks, only: [:index, :show] do
    member do
      get :stream
    end
  end

  # Админский API для загрузки и обработки медиафайлов
  namespace :admin do
    resources :tracks, only: [] do
      collection do
        post :presign_upload
        post :process_upload
      end
    end
  end
end