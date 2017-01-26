require('dotenv').load();

var stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.handler = function(event, context) {

  
};
