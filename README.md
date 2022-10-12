# Example code to show the values of the context for different identities in an AppSync resolver

## Deploy

* ```terraform init```
* ```terraform apply```

## Use

* Go to the appsync console

### Cognito

* Select the ```cognito-test``` API
* Go to Queries
* Log in as ```user1```/```Test.123456```
* Send query:

```graphql
query MyQuery {
  auth_info
}
```

Result:

```json
{
  "data": {
    "auth_info": "{\"authType\":\"User Pool Authorization\",\"identity\":{\"claims\":{\"sub\":\"af08acd8-f118-4016-a35d-2e47d43015a3\",\"cognito:groups\":[\"user\"],\"email_verified\":true,\"iss\":\"https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_4L0sooDv9\",\"cognito:username\":\"user1\",\"origin_jti\":\"c98cc3d8-0e89-490e-91b2-e0c209452d4e\",\"aud\":\"10f1mu8jtpi9asm1drp3a0cclo\",\"event_id\":\"d29a170c-4474-41e9-ae56-867eaa584604\",\"token_use\":\"id\",\"auth_time\":1664354661,\"exp\":1664358261,\"iat\":1664354661,\"jti\":\"bf352d13-d551-4655-adeb-7fbb9506533f\",\"email\":\"user1@example.com\"},\"defaultAuthStrategy\":\"DENY\",\"groups\":[\"user\"],\"issuer\":\"https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_4L0sooDv9\",\"sourceIp\":[\"83.173.202.165\"],\"sub\":\"af08acd8-f118-4016-a35d-2e47d43015a3\",\"username\":\"user1\"}}"
  }
}
```

### IAM

* Select the ```iam-test``` API
* Go to Queries
* Send the query:

```graphql
query MyQuery {
  auth_info
}
```

Result:

```json
{
  "data": {
    "auth_info": "{\"authType\":\"IAM Authorization\",\"identity\":{\"accountId\":\"278868411450\",\"cognitoIdentityAuthProvider\":null,\"cognitoIdentityAuthType\":null,\"cognitoIdentityId\":null,\"cognitoIdentityPoolId\":null,\"sourceIp\":[\"83.173.202.165\"],\"userArn\":\"arn:aws:iam::278868411450:user/sandbox_admin\",\"username\":\"AIDAUB3O2IQ5MG6P2QH3Z\"}}"
  }
}
```

### API key

* Select the ```apikey-test``` API
* Go to Queries
* Send the query:

```graphql
query MyQuery {
  auth_info
}
```

Result:

```json
{
  "data": {
    "auth_info": "{\"authType\":\"API Key Authorization\",\"identity\":null}"
  }
}
```

### Lambda

* Select the ```Lambda-test``` API
* Go to Queries
* Insert a token (any string would do)
* Send the query:

```graphql
query MyQuery {
  auth_info
}
```

Result:

```json
{
  "data": {
    "auth_info": "{\"authType\":\"Lambda Authorization\",\"identity\":{\"resolverContext\":{\"a\":\"test\",\"this\":\"is\"}}}"
  }
}
```

## Cleanup

* ```terraform destroy```
