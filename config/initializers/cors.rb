Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "*" # Для разработки разрешаем запросы с любого порта (например, с Vite/React/Vue на :5173 или :3001)

    resource "*",
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             expose: ["Content-Range", "Accept-Ranges", "Content-Length", "ETag"] # Критично для аудиоплееров и перемотки
  end
end