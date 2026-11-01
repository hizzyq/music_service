Rails.application.routes.draw do
  post "/auth/register", to: "authentication#register"
  post "/auth/login",    to: "authentication#login"

  resources :tracks, only: [:index, :show] do
    member do
      get :stream
    end
  end

  resources :playlists do
    member do
      post "tracks", to: "playlists#add_track"
      delete "tracks/:track_id", to: "playlists#remove_track"
    end
  end

  resources :history, only: [:index, :create]
  resources :recommendations, only: [:index]

  # Избранное (1-клик добавление/удаление)
  get  "/favorites",          to: "favorites#index"
  get  "/favorites/ids",      to: "favorites#ids"
  post "/favorites/:track_id", to: "favorites#toggle"

  # Админский API для загрузки, обработки и удаления медиафайлов
  namespace :admin do
    resources :tracks, only: [:destroy] do
      collection do
        post :presign_upload
        post :process_upload
      end
    end
  end
end