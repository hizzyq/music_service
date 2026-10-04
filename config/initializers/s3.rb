# frozen_string_literal: true
require "aws-sdk-s3"

S3_CLIENT = Aws::S3::Client.new(
  endpoint: ENV.fetch("S3_ENDPOINT", "http://localhost:9000"),
  access_key_id: ENV.fetch("S3_ACCESS_KEY_ID", "admin"),
  secret_access_key: ENV.fetch("S3_SECRET_ACCESS_KEY", "00000000"),
  region: ENV.fetch("S3_REGION", "us-east-1"),
  force_path_style: true
)

S3_PRESIGNER = Aws::S3::Presigner.new(client: S3_CLIENT)
S3_BUCKET_NAME = ENV.fetch("S3_BUCKET", "music")
