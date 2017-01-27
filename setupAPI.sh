#!/bin/bash

# Get variables
source .env

# Create the API
API_ID=$(aws apigateway create-rest-api \
--name ${AWS_LAMBDA_FUNCTIONNAME}-api \
--description "Rest API for ${AWS_LAMBDA_FUNCTIONNAME}" | \
  python -c "import sys, json; print(json.load(sys.stdin)['id'])")

if [ -n ${API_ID} ]; then
  echo "REST API created. ID: ${API_ID}"
else
  echo "REST API creation failed!"
  exit
fi

# Get ID of root resource
ROOT_ID=$(aws apigateway get-resources \
--rest-api-id ${API_ID} | \
  python -c "import sys, json; print(json.load(sys.stdin)['items'][0]['id'])")

if [ -n ${ROOT_ID} ]; then
  echo "Root resource ID: ${ROOT_ID}"
else
  echo "Failed to get root resource ID!"
  exit
fi

# Create a resource
RESOURCE_ID=$(aws apigateway create-resource \
--rest-api-id ${API_ID} \
--parent-id ${ROOT_ID} \
--path-part ${AWS_LAMBDA_FUNCTIONNAME}-manager | \
  python -c "import sys, json; print(json.load(sys.stdin)['id'])")

if [ -n ${RESOURCE_ID} ]; then
  echo "New resource created. ID: ${RESOURCE_ID}"
else
  echo "New resource creation failed!"
  exit
fi

# Create a POST method on the resource
METHOD=$(aws apigateway put-method \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method POST \
--authorization-type NONE | \
  python -c "import sys, json; print(json.load(sys.stdin)['httpMethod'])")

if [ -n ${METHOD} ]; then
  echo "POST method created for the resource."
else
  echo "POST method creation failed!"
  exit
fi

# Set the lambda function as the destination for the POST method
DESTINATION=$(aws apigateway put-integration \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method POST \
--type AWS \
--integration-http-method POST \
--uri arn:aws:apigateway:${AWS_LAMBDA_REGIONS}:lambda:path/2015-03-31/functions/arn:aws:lambda:${AWS_LAMBDA_REGIONS}:${AWS_ACCOUNT_ID}:function:${AWS_LAMBDA_FUNCTIONNAME}/invocations | \
  python -c "import sys, json; print(json.load(sys.stdin)['uri'])")

if [ -n ${DESTINATION} ]; then
  echo "${AWS_LAMBDA_FUNCTIONNAME} set as the destination for POST."
else
  echo "POST method destination failed!"
  exit
fi

# Set return type of POST method response to JSON
RESPONSE1=$(aws apigateway put-method-response \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method POST \
--status-code 200 \
--response-models "{\"application/json\": \"Empty\"}" | \
  python -c "import sys, json; print(json.load(sys.stdin)['statusCode'])")

if [ -n ${RESPONSE1} ]; then
  echo "POST method response set to JSON."
else
  echo "POST method response type setting failed!"
  exit
fi

# Set return type of POST method integration response to JSON
RESPONSE2=$(aws apigateway put-integration-response \
--rest-api-id ${API_ID} \
--resource-id ${RESOURCE_ID} \
--http-method POST \
--status-code 200 \
--response-templates "{\"application/json\": \"\"}" | \
  python -c "import sys, json; print(json.load(sys.stdin)['statusCode'])")

if [ -n ${RESPONSE2} ]; then
  echo "POST method integration response set to JSON."
else
  echo "POST method integration response type setting failed!"
  exit
fi

# Deploy the API
DEPLOYMENT_ID=$(aws apigateway create-deployment \
--rest-api-id ${API_ID} \
--stage-name prod | \
  python -c "import sys, json; print(json.load(sys.stdin)['id'])")

if [ -n ${DEPLOYMENT_ID} ]; then
  echo "API deployed. Deployment ID: ${DEPLOYMENT_ID}"
else
  echo "API deployment failed!"
  exit
fi


# Grant permissions for the API Gateway to invoke the Lambda function
STATEMENT1=$(aws lambda add-permission \
--function-name ${AWS_LAMBDA_FUNCTIONNAME} \
--statement-id ${AWS_LAMBDA_FUNCTIONNAME}-apigateway-test \
--action lambda:InvokeFunction \
--principal apigateway.amazonaws.com \
--source-arn "arn:aws:execute-api:us-east-1:${AWS_ACCOUNT_ID}:${API_ID}/*/POST/${AWS_LAMBDA_FUNCTIONNAME}-manager" | \
  python -c "import sys, json; print(json.load(sys.stdin)['Statement'])")

if [ -n ${STATEMENT1} ]; then
  echo "API Gateway permissions granted."
else
  echo "Failed to grant API Gateway permissions!"
  exit
fi

# Grant permissions for the deployed API to invoke the Lambda function
STATEMENT2=$(aws lambda add-permission \
--function-name ${AWS_LAMBDA_FUNCTIONNAME} \
--statement-id ${AWS_LAMBDA_FUNCTIONNAME}-apigateway-prod \
--action lambda:InvokeFunction \
--principal apigateway.amazonaws.com \
--source-arn "arn:aws:execute-api:us-east-1:${AWS_ACCOUNT_ID}:${API_ID}/prod/POST/${AWS_LAMBDA_FUNCTIONNAME}-manager" | \
 python -c "import sys, json; print(json.load(sys.stdin)['Statement'])")

if [ -n ${STATEMENT2} ]; then
 echo "Deployed API permissions granted."
else
 echo "Failed to grant deployed API permissions!"
 exit
fi

echo "Success! REST URL:  https://${API_ID}.execute-api.${AWS_LAMBDA_REGIONS}.amazonaws.com/prod/${AWS_LAMBDA_FUNCTIONNAME}-manager"
