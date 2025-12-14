// lib/screens/premium/subscribe_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../config/stripe_config.dart';
import '../../services/auth_service.dart';

class SubscribeScreen extends ConsumerStatefulWidget {
  final bool canDismiss;

  const SubscribeScreen({
    super.key,
    this.canDismiss = true,
  });

  @override
  ConsumerState<SubscribeScreen> createState() => _SubscribeScreenState();
}

class _SubscribeScreenState extends ConsumerState<SubscribeScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  Future<void> _initializeStripe() async {
    if (!StripeConfig.isConfigured) {
      setState(() {
        _errorMessage = 'Stripe is not configured yet. Please add your Stripe keys to lib/config/stripe_config.dart';
      });
      return;
    }

    try {
      // Initialize Stripe with publishable key
      Stripe.publishableKey = StripeConfig.publishableKey;
      Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;
      await Stripe.instance.applySettings();
      print('✅ Stripe initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize Stripe: $e');
      setState(() {
        _errorMessage = 'Failed to initialize payment system: $e';
      });
    }
  }

  Future<void> _handleSubscribe() async {
    if (!StripeConfig.isConfigured) {
      _showSnackBar('Stripe is not configured. Please contact support.', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print('🔄 Starting subscription process for user: ${user.uid}');

      // TODO: Call your Firebase Function to create payment intent
      // This is a placeholder - you'll need to implement the backend function
      // For now, we'll show a message
      
      // Example of what the flow should be:
      // 1. Call Firebase Function to create Stripe subscription
      // 2. Get client secret from response
      // 3. Present payment sheet with client secret
      // 4. On success, update Firestore user document
      
      // v1.0 Launch: Show "Coming Soon" message
      _showComingSoonDialog();

      // Placeholder for actual payment flow:
      // final result = await _presentPaymentSheet(clientSecret);
      // if (result) {
      //   await _updateUserToPremium();
      //   _showSnackBar('Successfully subscribed to Premium!', isError: false);
      //   Navigator.of(context).pop(true);
      // }

    } catch (e, stackTrace) {
      print('❌ Subscription error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar('Payment failed: $e', isError: true);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<bool> _presentPaymentSheet(String clientSecret) async {
    try {
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: StripeConfig.merchantDisplayName,
          style: ThemeMode.system,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      print('✅ Payment successful!');
      return true;
    } on StripeException catch (e) {
      print('❌ Stripe error: ${e.error.localizedMessage}');
      if (e.error.code == FailureCode.Canceled) {
        print('User canceled payment');
      }
      return false;
    }
  }

  Future<void> _updateUserToPremium() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
      'isPremium': true,
      'premiumExpiresAt': null, // null = active subscription (never expires)
      'subscriptionStartDate': FieldValue.serverTimestamp(),
    });

    print('✅ User updated to premium: ${user.uid}');
  }

  Future<void> _handleRestorePurchase() async {
    // TODO: Implement restore purchase logic
    // This should check if user has an active Stripe subscription
    // and update Firestore accordingly
    
    _showSnackBar('Restore purchase feature coming soon!', isError: false);
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Coming Soon!'),
          ],
        ),
        content: Text(
          'Premium subscriptions will be available soon!\n\n'
          'We\'re finalizing payment processing. In the meantime, '
          'enjoy your trial and stay tuned for updates!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.orange : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => widget.canDismiss,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Upgrade to Premium'),
          backgroundColor: Colors.deepPurple,
          elevation: 0,
          automaticallyImplyLeading: widget.canDismiss,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Crown icon
                Icon(
                  Icons.workspace_premium,
                  size: 80,
                  color: Colors.amber,
                ),
                SizedBox(height: 16),

                // Title
                Text(
                  'Upgrade to Premium',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),

                // Subtitle
                Text(
                  'Your trial has ended. Upgrade to continue battling!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),

                // Benefits list
                _buildBenefitItem(
                  icon: Icons.all_inclusive,
                  title: 'Unlimited Battles',
                  description: 'Challenge anyone, anytime',
                ),
                _buildBenefitItem(
                  icon: Icons.video_library,
                  title: 'Auto-Record Videos',
                  description: 'All performances saved automatically',
                ),
                _buildBenefitItem(
                  icon: Icons.replay,
                  title: 'Watch Replays Anytime',
                  description: 'Review your performances forever',
                ),
                _buildBenefitItem(
                  icon: Icons.support_agent,
                  title: 'Priority Support',
                  description: 'Get help when you need it',
                ),
                _buildBenefitItem(
                  icon: Icons.block,
                  title: 'No Ads',
                  description: 'Enjoy ad-free experience',
                ),
                SizedBox(height: 32),

                // Price display
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.deepPurple.shade200,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        StripeConfig.monthlyPrice,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      Text(
                        'per month',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Cancel anytime',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[900]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.orange[900]),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Subscribe button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _handleSubscribe,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: _isProcessing
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Subscribe Now',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                SizedBox(height: 12),

                // Restore purchase button
                TextButton(
                  onPressed: _isProcessing ? null : _handleRestorePurchase,
                  child: Text(
                    'Restore Purchase',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),

                // Maybe later button
                if (widget.canDismiss)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.green.shade700,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
