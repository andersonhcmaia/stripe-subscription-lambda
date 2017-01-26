require('dotenv').load();

var stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.handler = function(event, context) {

    stripe.customers.create({
      email: event.email,
      source: event.cc,
    }, function(err, customer) {
      if(err){
        context.fail(err);
      }
      else {
        stripe.subscriptions.create({
          customer: customer.id,
          plan: event.plan,
        }, function(err, subscription) {
          if(err){
            context.fail(err);
          }
          else{
            context.succeed({ customer: customer.id, success : true });
          }
        });
      }
    });
};
