from flask import Flask, request, jsonify, render_template
import stripe
import os

app = Flask(__name__)

# Set your Stripe API key from the environment variable
stripe.api_key = os.getenv('STRIPE_SECRET_KEY')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/create-charge', methods=['POST'])
def create_charge():
    try:
        data = request.json
        name = data['name']
        email = data['email']
        amount = data['amount']
        currency = data['currency']
        payment_method_id = data['payment_method_id']
        address = data['address']
        city = data['city']
        state = data['state']
        zip = data['zip']
        country = data['country']
        ip = data['ip']
        user_agent = data['user_agent']

        # Create a customer with detailed billing information
        customer = stripe.Customer.create(
            name=name,
            email=email,
            address={
                'line1': address,
                'city': city,
                'state': state,
                'postal_code': zip,
                'country': country
            }
        )

        # Attach the payment method to the customer
        stripe.PaymentMethod.attach(
            payment_method_id,
            customer=customer.id
        )

        # Set the default payment method on the customer
        stripe.Customer.modify(
            customer.id,
            invoice_settings={
                'default_payment_method': payment_method_id
            }
        )

        # Create a charge
        charge = stripe.Charge.create(
            amount=int(amount) * 100,  # Stripe expects the amount in cents
            currency=currency,
            customer=customer.id,
            source=payment_method_id,
            description="Test Charge",
            metadata={
                'ip_address': ip,
                'user_agent': user_agent
            }
        )

        return jsonify({
            'charge_id': charge['id'],
            'status': charge['status']
        })
    except Exception as e:
        return jsonify(error=str(e)), 403

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
