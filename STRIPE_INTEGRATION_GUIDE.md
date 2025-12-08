# Stripe Integration Guide

## Overview

The Stripe payment integration has been added to the `BookingGlobalViewModel` to handle payment processing for appointment bookings.

## What's Implemented

### 1. BookingGlobalViewModel Updates

- **New Properties:**

  - `paymentSheet`: Stores the Stripe PaymentSheet instance
  - `paymentResult`: Stores the payment result
  - `isPaymentReady`: Boolean indicating if payment is ready

- **New Methods:**
  - `preparePaymentSheet(amount:)`: Fetches payment intent from backend and prepares Stripe
  - `onPaymentCompletion(result:)`: Handles payment completion and creates booking

### 2. BookingConfirmationView Updates

- Displays Stripe PaymentSheet button
- Automatically prepares payment when view appears
- Shows "Preparing Payment..." state while loading
- Navigates to success screen after successful payment

### 3. BroccoliApp Updates

- Added Stripe URL callback handler via `.onOpenURL`
- Handles deep links for payment authentication redirects

### 4. Info.plist Updates

- Added custom URL scheme: `broccoli://`
- Allows app to handle Stripe redirect URLs

## Backend Requirements

Your backend needs to implement a payment endpoint at:

```
POST /api/payment-sheet
```

### Request Format:

```json
{
  "amount": 5000, // Amount in cents (e.g., $50.00 = 5000)
  "currency": "usd" // Currency code (usd, eur, gbp)
}
```

### Response Format:

```json
{
  "customer": "cus_xxxxxxxxxxxxx",
  "customerSessionClientSecret": "cuss_xxxxxxxxxxxxx",
  "paymentIntent": "pi_xxxxxxxxxxxxx_secret_xxxxxxxxxxxxx",
  "publishableKey": "pk_test_xxxxxxxxxxxxx"
}
```

### Backend Implementation (Node.js Example):

```javascript
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

app.post("/api/payment-sheet", async (req, res) => {
  const { amount, currency } = req.body;

  try {
    // Get or create customer
    const customer = await stripe.customers.create();

    // Create customer session
    const customerSession = await stripe.customerSessions.create({
      customer: customer.id,
      components: {
        payment_element: {
          enabled: true,
          features: {
            payment_method_save: true,
            payment_method_remove: true,
          },
        },
      },
    });

    // Create payment intent
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount,
      currency: currency,
      customer: customer.id,
      automatic_payment_methods: {
        enabled: true,
      },
    });

    res.json({
      customer: customer.id,
      customerSessionClientSecret: customerSession.client_secret,
      paymentIntent: paymentIntent.client_secret,
      publishableKey: process.env.STRIPE_PUBLISHABLE_KEY,
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
```

## Installing Stripe SDK

### Option 1: Swift Package Manager (Recommended)

1. In Xcode, go to **File > Add Packages...**
2. Enter the Stripe SDK URL: `https://github.com/stripe/stripe-ios-spm`
3. Select version **23.0.0** or later
4. Add the following products:
   - **StripePaymentSheet**

### Option 2: CocoaPods

Add to your `Podfile`:

```ruby
pod 'StripePaymentSheet', '~> 23.0'
```

Then run:

```bash
pod install
```

## Configuration

### 1. URL Scheme (Already Added)

The custom URL scheme `broccoli://` has been added to Info.plist for handling payment redirects.

### 2. Stripe Publishable Key

The publishable key is fetched from your backend's `/payment-sheet` endpoint, so no hardcoding is needed in the app.

## Payment Flow

1. **User fills booking form** → Selects date, time slot
2. **User navigates to BookingConfirmationView**
3. **View automatically calls** `preparePaymentSheet(amount:)`
4. **Backend creates PaymentIntent** and returns necessary keys
5. **Stripe PaymentSheet is displayed** when user taps "Confirm Booking & Pay"
6. **User completes payment** (card, Apple Pay, etc.)
7. **On success** → Booking is created via `submitBooking()`
8. **Navigate to PaymentSuccessView**

## Testing

### Test Cards (Stripe Test Mode)

- **Success:** `4242 4242 4242 4242`
- **Requires Authentication:** `4000 0027 6000 3184`
- **Decline:** `4000 0000 0000 0002`

Any future expiry date and any 3-digit CVC.

## Error Handling

Errors are displayed via:

- `bookingViewModel.showErrorToast`: Boolean to show alert
- `bookingViewModel.errorMessage`: Error message text

Common error scenarios:

- Invalid payment amount
- Network failure when preparing payment
- Backend endpoint not implemented
- Payment declined by card issuer
- User cancels payment

## Security Considerations

1. **Never hardcode Stripe secret keys** in the iOS app
2. **Always use HTTPS** for backend communication
3. **Authenticate API requests** - The code adds Bearer token from SecureStore
4. **Validate amounts on backend** - Don't trust client-side amounts
5. **Use webhook verification** for payment confirmation on backend

## Next Steps

1. **Install Stripe SDK** via Swift Package Manager
2. **Implement backend endpoint** at `/api/payment-sheet`
3. **Configure Stripe account** and get API keys
4. **Test with Stripe test cards**
5. **Implement webhook handler** on backend for payment confirmations
6. **Add delayed payment method handling** if supporting bank transfers

## Support Resources

- [Stripe iOS SDK Documentation](https://stripe.com/docs/payments/accept-a-payment?platform=ios)
- [Stripe API Reference](https://stripe.com/docs/api)
- [PaymentSheet Documentation](https://stripe.com/docs/payments/accept-a-payment?platform=ios&ui=payment-sheet)
- [Customer Session API](https://stripe.com/docs/api/customer_sessions)
