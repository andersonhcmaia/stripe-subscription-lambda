# Stripe Subscription Lambda
Integration between Amazon AWS Lambda and Stripe Subscriptions. Intended to be used with Stripe Checkout or Stripe.js.

## Description

This project provides a Lambda function to act as a back-end server for Stripe Subscriptions. It automatically bundles and deploys the lambda function. The script for deploying the REST API for the same function using Amazon AWS API Gateway is also provided. With these two components communication between front-end applications and Stripe can be achieved.

## Installation

1. `git clone git@github.com:henriquegrando/stripe-subscription-lambda.git`
2. `cd stripe-subscription-lambda`
3. `npm install`
4. Update your credentials in `sample.env` and rename to `.env`
5. Update your `lambda.json` [OPTIONAL]


## Uploading Lambda Function

To simply deploy the lambda function `gulp deploy`. The following tasks are also provided.

### `gulp clean`

Removes any existing builds. Deletes the `./dist` dir and `./dist.zip`

### `gulp js`

Prepares the source and dependencies. Places the `index.js` and production dependencies (node_modules) in the `./dist` dir.

The optional `--dev` flag skips code optimization.

### `gulp test`

Runs the mocha tests found at `./test/test.js` against the compiled lambda at `./dist/index.js`.

`gulp build` & `gulp deploy` run `gulp test` as part of their pipeline.

If an error is returned the build is terminated.

### `gulp zip`

Zips `./dist` directory. Current implementation is naive, but can be made extensible.

### `gulp deploy`

Deploys `./dist.zip` using the same method as [JAWS deploy command @furf redux](https://github.com/furf/JAWS/blob/improvement/jaws-deploy-update/cli/lib/main.js).

`gulp deploy --dev` will deploy the non optimized `dist` folder.

## REST API Setup

In order to deploy the REST API for communication over HTTP using the POST method, run the provided script.

`./setupAPI.sh`

## Make New Subscription

Communicate with the REST API through the POST method, providing a JSON in the following format:

`       \
{
  "plan": "the-desired-subscription-plan-id",
  "cc": "the-payment-source-token",
  "email": "email-of-the-customer-to-be-subscribed"
}`

* `plan`: should be a plan already registered in Stripe (this can be done through Stripe's dashboard).
* `cc`: is the payment source token generated by Stripe Checkout or Stripe.js.
* `email`: is the email used to create a new customer.

The response will be a JSON in the following format:

`       \
{
  "customer": "created-customer-id",
  "subscription": "created-subscription-id",
  "success: true"
}
`

Request example using curl:

`curl -X POST -d "{\"plan\": \"your-plan\", \"cc\": \"tok_gahywnxij371snxma923jsn\", \"email\": \"customer@email.com\"}" https://your-rest-api-url.com `
