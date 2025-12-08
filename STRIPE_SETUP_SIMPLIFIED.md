# Stripe Payment Setup Guide (Simplified Approach)

## Overview

Your implementation uses a **simplified payment flow** where the booking API creates the payment intent and returns it directly. This eliminates the need for a separate payment-sheet endpoint.

## ✅ What You Have

### Current API Response (Working)

```json
POST /api/bookings

Response:
{
  "success": true,
  "booking": {
    "id": 90,
    "amount": "50.00",
    "payment_status": "pending",
    "stripe_payment_intent_id": "pi_xxxxx"
  },
  "payment_intent": "pi_xxxxx_secret_xxxxx"  ← App uses this
}
```

### Current Flow

1. User clicks "Confirm Booking & Pay"
2. App calls `/bookings` → Creates booking + payment intent
3. Backend returns `payment_intent` secret
4. App displays Stripe PaymentSheet
5. User pays → Success screen

## 🔧 Setup Required

### Step 1: Add Stripe Publishable Key

Open `/Broccoli/App/Environment/AppEnvironment.swift` and add your keys:

```swift
public static let development = AppEnvironment(
    apiBaseURL: "https://admin.broccolicare.ie/api",
    isDebug: true,
    enableLogging: true,
    stripePublishableKey: "pk_test_YOUR_TEST_KEY_HERE" // ← Add your test key
)

public static let production = AppEnvironment(
    apiBaseURL: "https://admin.broccolicare.ie/api",
    isDebug: false,
    enableLogging: false,
    stripePublishableKey: "pk_live_YOUR_LIVE_KEY_HERE" // ← Add your live key
)
```

**Get your keys from:**

- Stripe Dashboard → Developers → API keys
- Test: `pk_test_...`
- Live: `pk_live_...`

### Step 2: Backend - No Changes Needed! ✨

Your backend already works perfectly. It:

- Creates booking
- Creates Stripe PaymentIntent
- Returns `payment_intent` in response

### Step 3: Test Payment

Use Stripe test cards:

- **Success**: `4242 4242 4242 4242`
- **Requires 3D Secure**: `4000 0027 6000 3184`
- **Declined**: `4000 0000 0000 0002`

Any future date, any 3-digit CVC.

## 📱 User Flow

### Scenario 1: Payment Required

```
User → Confirm Booking & Pay
  ↓
Create booking (has payment_intent)
  ↓
Show Stripe payment sheet
  ↓
User enters card & pays
  ↓
Success screen
```

### Scenario 2: Subscription User (No Payment)

```
User → Confirm Booking & Pay
  ↓
Create booking (no payment_intent)
  ↓
Success screen (skip payment)
```

## 🚫 What You DON'T Need

❌ `/payment-sheet` endpoint  
❌ Customer session creation  
❌ Separate payment intent creation  
❌ Customer ID management

Your booking API handles everything!

## 🔐 Security Best Practices

### ✅ DO:

- Keep secret key (`sk_`) on server only
- Use publishable key (`pk_`) in app
- Validate payment on backend via webhooks
- Store publishable key in `AppEnvironment`

### ❌ DON'T:

- Hardcode secret keys in app
- Trust payment status from client
- Skip webhook verification
- Use production keys in development

## 🐛 Troubleshooting

### Error: "Stripe publishable key not configured"

**Fix:** Add your `pk_test_...` key to `AppEnvironment.swift`

### Error: "Payment failed - unexpected error"

**Causes:**

1. Invalid publishable key
2. Payment intent expired (>24 hours old)
3. Network connectivity issue

**Fix:**

- Check publishable key is correct
- Ensure booking creates fresh payment intent
- Test with valid test card

### Payment succeeds but booking shows pending

**This is normal!**

- Payment takes time to process
- Use webhooks to update booking status
- Implement webhook handler: `/webhooks/stripe`

## 🔗 Webhook Setup (Important!)

Your backend should listen for Stripe events:

```javascript
// /webhooks/stripe
app.post("/webhooks/stripe", async (req, res) => {
  const sig = req.headers["stripe-signature"];
  const event = stripe.webhooks.constructEvent(
    req.body,
    sig,
    process.env.STRIPE_WEBHOOK_SECRET
  );

  if (event.type === "payment_intent.succeeded") {
    const paymentIntent = event.data.object;
    // Update booking payment_status to 'paid'
    await Booking.update(
      { payment_status: "paid" },
      { where: { stripe_payment_intent_id: paymentIntent.id } }
    );
  }

  res.json({ received: true });
});
```

## 📚 Additional Resources

- [Stripe iOS SDK Docs](https://stripe.com/docs/payments/accept-a-payment?platform=ios)
- [Payment Intents API](https://stripe.com/docs/api/payment_intents)
- [Webhooks Guide](https://stripe.com/docs/webhooks)
- [Test Cards](https://stripe.com/docs/testing)

## ✨ Summary

Your implementation is **simpler and more efficient** than the full customer session approach:

| Feature            | Your Approach   | Full Customer Session              |
| ------------------ | --------------- | ---------------------------------- |
| Endpoints          | 1 (`/bookings`) | 2 (`/bookings` + `/payment-sheet`) |
| Backend complexity | Low             | High                               |
| Saved cards        | No              | Yes                                |
| Guest checkout     | Yes             | Yes                                |
| Setup time         | Fast            | Slow                               |

For most use cases, your approach is perfect! Only add customer sessions later if you need saved payment methods.
