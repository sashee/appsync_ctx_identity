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

# Lambda

resource "aws_appsync_graphql_api" "lambda" {
  name                = "lambda-test"
  schema              = file("schema.graphql")
  authentication_type = "AWS_LAMBDA"
	lambda_authorizer_config {
		authorizer_uri = aws_lambda_function.authorizer.arn
	}
}

module "lambda-appsync-resources" {
  source  = "./modules/appsync-resources"
  api = aws_appsync_graphql_api.lambda
}

resource "aws_lambda_permission" "appsync_lambda_authorizer" {
	action        = "lambda:InvokeFunction"
	function_name = aws_lambda_function.authorizer.function_name
	principal     = "appsync.amazonaws.com"
	source_arn    = aws_appsync_graphql_api.lambda.arn
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "/tmp/lambda-${random_id.id.hex}.zip"
  source {
    content  = <<EOF
module.exports.handler = async (event) => {
	return {
		isAuthorized: true,
		deniedFields: [],
		resolverContext: {
			this: "is",
			a: "test",
		},
		ttlOverride: 0,
	};
};
EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "authorizer" {
  function_name = "authorizer-${random_id.id.hex}"

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  handler = "index.handler"
  runtime = "nodejs16.x"
  role    = aws_iam_role.lambda_exec.arn
}

resource "aws_cloudwatch_log_group" "authorizer_loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = 14
}

data "aws_iam_policy_document" "lambda_exec_policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_exec_policy" {
  role   = aws_iam_role.lambda_exec.id
  policy = data.aws_iam_policy_document.lambda_exec_policy.json
}

resource "aws_iam_role" "lambda_exec" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
	{
	  "Action": "sts:AssumeRole",
	  "Principal": {
		"Service": "lambda.amazonaws.com"
	  },
	  "Effect": "Allow"
	}
  ]
}
EOF
}
