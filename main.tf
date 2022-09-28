provider "aws" {
}

data "aws_region" "current" {}

resource "random_id" "id" {
  byte_length = 8
}

# cognito

resource "aws_appsync_graphql_api" "cognito" {
  name                = "cognito-test"
  schema              = file("schema.graphql")
  authentication_type = "AMAZON_COGNITO_USER_POOLS"
  user_pool_config {
    default_action = "DENY"
    user_pool_id   = aws_cognito_user_pool.pool.id
  }
}

module "cognito-appsync-resources" {
  source  = "./modules/appsync-resources"
  api = aws_appsync_graphql_api.cognito
}

resource "aws_cognito_user_pool" "pool" {
  name = "test-${random_id.id.hex}"
}

resource "aws_cognito_user_pool_client" "client" {
  name = "client"

  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_group" "user" {
  name         = "user"
  user_pool_id = aws_cognito_user_pool.pool.id
}

# database

resource "aws_dynamodb_table" "users" {
  name           = "Users-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "sub"

  attribute {
    name = "sub"
    type = "S"
  }
}

resource "aws_dynamodb_table" "documents" {
  name           = "Documents-${random_id.id.hex}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

resource "aws_cognito_user" "user1" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = "user1"
	password = "Test.123456"
  attributes = {
    email          = "user1@example.com"
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "example" {
  user_pool_id = aws_cognito_user_pool.pool.id
  group_name   = aws_cognito_user_group.user.name
  username     = aws_cognito_user.user1.username
}

# api key

resource "aws_appsync_graphql_api" "apikey" {
  name                = "apikey-test"
  schema              = file("schema.graphql")
  authentication_type = "API_KEY"
}

module "apikey-appsync-resources" {
  source  = "./modules/appsync-resources"
  api = aws_appsync_graphql_api.apikey
}

resource "aws_appsync_api_key" "apikey" {
  api_id  = aws_appsync_graphql_api.apikey.id
}

# IAM

resource "aws_appsync_graphql_api" "iam" {
  name                = "iam-test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_IAM"
}

module "iam-appsync-resources" {
  source  = "./modules/appsync-resources"
  api = aws_appsync_graphql_api.iam
}
