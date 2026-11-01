#!/bin/sh
set -e

echo "== [1/2] Running Rails Minitest Suite inside container =="
docker run --rm \
  --network music_service_default \
  -v "$(pwd):/app:z" \
  -e RAILS_ENV=test \
  -e DB_HOST=music-postgres \
  -e S3_ENDPOINT=http://minio-storage:9000 \
  music_backend:latest \
  bundle exec rails test

echo "== All Backend Tests Passed! =="
