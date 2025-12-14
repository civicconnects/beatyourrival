// lib/config/stripe_config.dart

/// Stripe Configuration
/// 
/// To get your keys:
/// 1. Go to: https://dashboard.stripe.com/test/apikeys
/// 2. Copy "Publishable key" (starts with pk_test_)
/// 3. Go to: https://dashboard.stripe.com/test/products
/// 4. Create a product with monthly subscription
/// 5. Copy the "Price ID" (starts with price_)
class StripeConfig {
  // TODO: Replace with your actual Stripe test publishable key
  // Get from: https://dashboard.stripe.com/test/apikeys
  static const String publishableKey = 'pk_test_YOUR_KEY_HERE';
  
  // TODO: Replace with your Stripe Price ID for monthly subscription
  // Get from: https://dashboard.stripe.com/test/products
  static const String monthlyPriceId = 'price_YOUR_PRICE_ID_HERE';
  
  // Monthly subscription price (for display only)
  static const String monthlyPrice = '\$9.99';
  
  // Merchant display name (shows in payment sheet)
  static const String merchantDisplayName = 'BeatYourRival';
  
  // Return URL after payment (for redirect flow, if needed)
  static const String returnUrl = 'beatyourrival://payment-success';
  
  /// Check if Stripe is properly configured
  static bool get isConfigured {
    return publishableKey != 'pk_test_YOUR_KEY_HERE' && 
           publishableKey.startsWith('pk_') &&
           monthlyPriceId != 'price_YOUR_PRICE_ID_HERE' &&
           monthlyPriceId.startsWith('price_');
  }
}
