# 💳 Stripe Setup Guide for BeatYourRival

## 🎯 Goal
Set up Stripe to accept subscription payments in your Flutter app.

---

## Step 1: Create Stripe Account (5 minutes)

1. **Go to:** https://stripe.com/
2. **Click:** "Start now" or "Sign up"
3. **Enter:**
   - Email address
   - Password
   - Business name: "BeatYourRival" (or your company name)
4. **Verify email**
5. **Complete onboarding** (can skip optional steps for now)

---

## Step 2: Get Your API Keys (1 minute)

### For Testing (Use This First):

1. **Go to:** https://dashboard.stripe.com/test/apikeys
2. **Copy these keys:**
   - **Publishable key:** `pk_test_...` (starts with `pk_test`)
   - **Secret key:** `sk_test_...` (starts with `sk_test`)

### For Production (Later):

1. **Switch to Live mode** (toggle in top right)
2. **Go to:** https://dashboard.stripe.com/apikeys
3. **Copy live keys:**
   - **Publishable key:** `pk_live_...`
   - **Secret key:** `sk_live_...`

**⚠️ IMPORTANT:** 
- Publishable key = Safe to use in Flutter app
- Secret key = NEVER put in Flutter app (use backend only)

---

## Step 3: Create Subscription Product (3 minutes)

1. **Go to:** https://dashboard.stripe.com/test/products
2. **Click:** "+ Add product"
3. **Fill out:**
   - **Name:** "BeatYourRival Premium"
   - **Description:** "Unlimited battles, auto-record videos, watch replays"
   - **Pricing:**
     - **Model:** Recurring
     - **Price:** $9.99 USD (or your chosen price)
     - **Billing period:** Monthly
   - **Statement descriptor:** "BEATRIVALS" (shows on credit card statement)
4. **Click:** "Save product"
5. **Copy the Price ID:** Looks like `price_xxx...` (you'll need this!)

---

## Step 4: Configure Flutter App (I'll do this!)

I'll add these keys to your Flutter app:

**Publishable Key goes in:** `lib/config/stripe_config.dart`
```dart
class StripeConfig {
  static const String publishableKey = 'pk_test_YOUR_KEY_HERE';
  static const String priceId = 'price_YOUR_PRICE_ID_HERE';
}
```

**Secret Key goes in:** Firebase Cloud Function (backend)
- Never in Flutter app code!
- Used for creating payment intents server-side

---

## Step 5: Test Payment Flow

**Test Card Numbers (Stripe provides these):**

✅ **Success:**
- Card: `4242 4242 4242 4242`
- Date: Any future date (e.g., 12/34)
- CVC: Any 3 digits (e.g., 123)
- ZIP: Any 5 digits (e.g., 12345)

❌ **Decline:**
- Card: `4000 0000 0000 0002`

🔄 **Requires 3D Secure:**
- Card: `4000 0025 0000 3155`

---

## Step 6: Set Up Backend (Firebase Functions)

**Why needed:**
- Stripe Secret Key must stay secret
- Create payment intents server-side
- Handle webhooks securely

**I'll create a simple Firebase Function for you:**

`functions/index.js`:
```javascript
const functions = require('firebase-functions');
const stripe = require('stripe')(functions.config().stripe.secret_key);
const admin = require('firebase-admin');
admin.initializeApp();

// Create payment intent
exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  // Verify user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const { priceId } = data;
  
  try {
    // Create Stripe customer
    const customer = await stripe.customers.create({
      metadata: {
        firebaseUID: context.auth.uid,
      },
    });

    // Create subscription
    const subscription = await stripe.subscriptions.create({
      customer: customer.id,
      items: [{ price: priceId }],
      payment_behavior: 'default_incomplete',
      payment_settings: { save_default_payment_method: 'on_subscription' },
      expand: ['latest_invoice.payment_intent'],
    });

    return {
      subscriptionId: subscription.id,
      clientSecret: subscription.latest_invoice.payment_intent.client_secret,
    };
  } catch (error) {
    throw new functions.https.HttpsError('internal', error.message);
  }
});

// Handle successful payment webhook
exports.handleStripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = functions.config().stripe.webhook_secret;

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (err) {
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  // Handle subscription payment succeeded
  if (event.type === 'invoice.payment_succeeded') {
    const invoice = event.data.object;
    const customerId = invoice.customer;
    
    // Get Firebase UID from customer metadata
    const customer = await stripe.customers.retrieve(customerId);
    const firebaseUID = customer.metadata.firebaseUID;
    
    // Update user in Firestore
    await admin.firestore().collection('Users').doc(firebaseUID).update({
      isPremium: true,
      premiumExpiresAt: null, // null = never expires (active subscription)
      stripeCustomerId: customerId,
      lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  res.json({ received: true });
});
```

**Deploy:**
```bash
firebase functions:config:set stripe.secret_key="sk_test_YOUR_SECRET_KEY"
firebase deploy --only functions
```

---

## Step 7: Testing Checklist

- [ ] Test mode enabled in Stripe dashboard
- [ ] Test card works (4242...)
- [ ] Payment creates subscription in Stripe
- [ ] User's `isPremium` updates to `true` in Firestore
- [ ] User can access battles after payment
- [ ] "Restore Purchase" works for existing subscribers

---

## Step 8: Go Live (Later)

When ready for production:

1. **Complete Stripe onboarding:**
   - Add business details
   - Add bank account (for payouts)
   - Verify identity
   
2. **Switch to Live mode:**
   - Toggle "Test mode" OFF in Stripe dashboard
   - Update app with live publishable key
   - Update Firebase Functions with live secret key
   
3. **Set up webhooks:**
   - Add webhook endpoint in Stripe dashboard
   - Point to your Firebase Function URL
   - Select events: `invoice.payment_succeeded`, `customer.subscription.deleted`

---

## 💰 Pricing Recommendations

**Monthly Subscription:**
- **$9.99/month** - Industry standard for niche apps
- **$4.99/month** - Lower barrier, higher conversion
- **$14.99/month** - Premium positioning

**Annual Subscription (Optional):**
- **$99.99/year** - Save ~17% vs monthly
- **$79.99/year** - Save ~33% vs monthly

**Free Trial:**
- 3 days (current) - Quick decision
- 7 days (recommended) - More time to engage
- 14 days - Maximum trial period

---

## 🔒 Security Best Practices

✅ **DO:**
- Use publishable key in Flutter app
- Keep secret key in Firebase Functions only
- Validate payments server-side
- Use webhooks for subscription updates
- Store customer ID in Firestore

❌ **DON'T:**
- Put secret key in Flutter app
- Trust client-side payment status
- Skip webhook verification
- Store credit card info (Stripe handles this)

---

## 📞 Support

**Stripe Documentation:**
- Subscriptions: https://stripe.com/docs/billing/subscriptions/overview
- Flutter: https://stripe.com/docs/payments/accept-a-payment?platform=flutter
- Webhooks: https://stripe.com/docs/webhooks

**Stripe Test Cards:**
https://stripe.com/docs/testing

**Stripe Dashboard:**
- Test mode: https://dashboard.stripe.com/test/dashboard
- Live mode: https://dashboard.stripe.com/dashboard

---

## 🎯 What You Need to Give Me

To complete the subscribe screen integration, I need:

1. **Stripe Publishable Key** (starts with `pk_test_`)
2. **Stripe Price ID** (starts with `price_`)
3. **Monthly price** (e.g., $9.99)

**Where to find:**
- Publishable key: https://dashboard.stripe.com/test/apikeys
- Price ID: https://dashboard.stripe.com/test/products (after creating product)

**Send me these 3 things and I'll integrate everything!** 🚀
