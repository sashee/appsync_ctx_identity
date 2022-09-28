variable "api" {
}

resource "aws_appsync_datasource" "none" {
  api_id           = var.api.id
  name             = "none"
  type             = "NONE"
}

# resolvers

resource "aws_appsync_resolver" "resolver" {
  api_id           = var.api.id
  data_source = aws_appsync_datasource.none.name
  type        = "Query"
  field       = "auth_info"
  request_template = <<EOF
{
  "version": "2018-05-29",
	"payload": {
		"authType": $util.toJson($util.authType()),
		"identity": $util.toJson($ctx.identity)
	}
}
EOF

  response_template = <<EOF
$util.toJson($ctx.result)
EOF
}
