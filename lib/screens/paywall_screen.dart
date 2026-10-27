import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../services/subscription_service.dart';
import '../services/stripe_payment_service.dart';

class PaywallScreen extends StatefulWidget {
  final AppState state;
  final VoidCallback? onCompleted;

  const PaywallScreen({
    super.key,
    required this.state,
    this.onCompleted,
  });

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  SubscriptionPlanTier _selectedTier = SubscriptionPlanTier.standard;
  bool _isLoading = false;
  String? _errorMessage;

  final StripePaymentService _stripeService = StripePaymentService();

  @override
  void initState() {
    super.initState();
    _stripeService.initialize();
  }

  Future<void> _handlePaymentAction() async {
    final user = widget.state.authService.currentUser;
    final userId = user?.uid ?? 'guest_${DateTime.now().millisecondsSinceEpoch}';
    final email = user?.email ?? 'member@stillwater.suite';

    if (_selectedTier == SubscriptionPlanTier.free) {
      // Free tier activation
      setState(() => _isLoading = true);
      await widget.state.subscriptionService.activatePlan(
        userId,
        SubscriptionPlanTier.free,
      );
      setState(() => _isLoading = false);
      if (mounted) {
        widget.onCompleted?.call();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final planName = _selectedTier == SubscriptionPlanTier.pro ? 'Pro Sovereign' : 'Standard Suite';
    final amountGbp = _selectedTier == SubscriptionPlanTier.pro ? 29.99 : 9.99;
    final planId = _selectedTier == SubscriptionPlanTier.pro ? 'plan_herb_pro_gbp' : 'plan_herb_standard_gbp';

    try {
      // 1. Create or fetch PaymentSheet parameters from Sovereign backend
      final session = await _stripeService.createPaymentSheetSession(
        userId: userId,
        email: email,
        planId: planId,
        amountGbp: amountGbp,
      );

      if (session == null) {
        throw Exception('Failed to generate secure Stripe payment intent');
      }

      final clientSecret = session['paymentIntent'] as String;
      final customerId = session['customerId'] as String;
      final ephemeralKey = session['ephemeralKey'] as String;
      final isSimulated = session['isSimulated'] == true;

      // 2. Present Native Android Stripe PaymentSheet
      final success = await _stripeService.presentMobilePaymentSheet(
        clientSecret: clientSecret,
        customerId: customerId,
        ephemeralKeySecret: ephemeralKey,
        planName: planName,
        amountGbp: amountGbp,
        isSimulated: isSimulated,
      );

      if (success) {
        // 3. Mark subscription active in Firestore users/{uid} & AppState
        await widget.state.subscriptionService.activatePlan(
          userId,
          _selectedTier,
          paymentMethod: isSimulated ? 'stripe_test_simulated' : 'stripe_google_pay',
        );

        if (mounted) {
          _showSuccessCelebration(planName);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment could not be completed: ${e.toString().replaceAll("Exception: ", "")}';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessCelebration(String planName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevation2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to $planName',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your subscription is active across Herb and the entire Stillwater Sovereign Suite.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onCompleted?.call();
                },
                child: const Text('Enter Herb Vault', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyTestCardHelper() {
    Clipboard.setData(const ClipboardData(text: '4242424242424242'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Test card copied: 4242 4242 4242 4242 (Use any future exp & any 3 digits)'),
        backgroundColor: AppColors.surfaceElevation3,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Suite Crest
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevation2,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Center(
                      child: Icon(Icons.castle_rounded, color: AppColors.primary, size: 28),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Center(
                  child: Text(
                    'STILLWATER SOVEREIGN SUITE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                Center(
                  child: Text(
                    'All-Access Membership',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      '⚡ Unlocks Herb + Entire Stillwater Suite',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Test Card Convenience Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevation2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.amberAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Stripe Test Mode (GB)',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: AppColors.primaryLight,
                        ),
                        icon: const Icon(Icons.copy, size: 12),
                        label: const Text('Test Card', style: TextStyle(fontSize: 11)),
                        onPressed: _copyTestCardHelper,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. FREE PLAN CARD
                _buildPlanCard(
                  tier: SubscriptionPlanTier.free,
                  title: 'Community Free',
                  price: '£0',
                  frequency: 'forever',
                  features: const [
                    'Standard offline catalogue browsing',
                    'Local on-device stash storage',
                    'Manual cloud backup',
                  ],
                ),
                const SizedBox(height: 12),

                // 2. STANDARD SUITE PLAN CARD
                _buildPlanCard(
                  tier: SubscriptionPlanTier.standard,
                  title: 'Standard Suite',
                  price: '£9.99',
                  frequency: 'per month',
                  badgeText: 'POPULAR',
                  badgeColor: AppColors.primary,
                  features: const [
                    'Automated multi-device cloud sync on herb-db-0',
                    'PromptResources access (global prompt library)',
                    'PromptTool Studio access (generation pipeline)',
                    'Persona integration & sensory bridge',
                  ],
                ),
                const SizedBox(height: 12),

                // 3. PRO SOVEREIGN PLAN CARD
                _buildPlanCard(
                  tier: SubscriptionPlanTier.pro,
                  title: 'Pro Sovereign',
                  price: '£29.99',
                  frequency: 'per month',
                  badgeText: 'ELITE ACCESS',
                  badgeColor: const Color(0xFF6366F1), // Indigo accent
                  features: const [
                    'Everything in Standard Suite',
                    'Herb AI Vision Telemetry (Gemini Vision Terpenes)',
                    'PromptMaster SPA full registry suite access',
                    'Priority real-time sync & unlimited generation',
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 11)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Button (Google Pay / Card / Free)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : _handlePaymentAction,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_selectedTier != SubscriptionPlanTier.free) ...[
                              const Icon(Icons.lock_outline, size: 16),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                _selectedTier == SubscriptionPlanTier.free
                                    ? 'Continue on Free Plan'
                                    : _selectedTier == SubscriptionPlanTier.pro
                                        ? 'Subscribe Pro · £29.99/mo'
                                        : 'Subscribe Standard · £9.99/mo',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 14),

                // Offline mode bypass fallback
                Center(
                  child: TextButton(
                    onPressed: () {
                      widget.state.setBypassAuth(true);
                      widget.onCompleted?.call();
                    },
                    child: const Text(
                      'Continue in Local Guest Mode',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
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

  Widget _buildPlanCard({
    required SubscriptionPlanTier tier,
    required String title,
    required String price,
    required String frequency,
    required List<String> features,
    String? badgeText,
    Color? badgeColor,
  }) {
    final isSelected = _selectedTier == tier;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceElevation2 : AppColors.surfaceElevation1,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? AppColors.primary : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: (badgeColor ?? AppColors.primary).withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: badgeColor ?? AppColors.primaryLight,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(width: 6),
                Text(
                  '/$frequency',
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, color: AppColors.primary, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
