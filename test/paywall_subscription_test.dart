import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:herb_app/screens/paywall_screen.dart';
import 'package:herb_app/services/subscription_service.dart';
import 'package:herb_app/state/app_state.dart';
import 'package:herb_app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubscriptionPlanTier tests', () {
    test('tier parsing and getters', () {
      expect(SubscriptionPlanTier.fromId('free'), SubscriptionPlanTier.free);
      expect(SubscriptionPlanTier.fromId('standard'), SubscriptionPlanTier.standard);
      expect(SubscriptionPlanTier.fromId('pro'), SubscriptionPlanTier.pro);
      expect(SubscriptionPlanTier.fromId('sovereign'), SubscriptionPlanTier.pro);
      expect(SubscriptionPlanTier.fromId('unknown'), SubscriptionPlanTier.free);

      expect(SubscriptionPlanTier.free.priceMonthlyGbp, 0.0);
      expect(SubscriptionPlanTier.standard.priceMonthlyGbp, 9.99);
      expect(SubscriptionPlanTier.pro.priceMonthlyGbp, 29.99);

      expect(SubscriptionPlanTier.free.isSubscribed, isFalse);
      expect(SubscriptionPlanTier.standard.isSubscribed, isTrue);
      expect(SubscriptionPlanTier.pro.isSubscribed, isTrue);
    });

    test('SubscriptionService default state', () {
      final sub = SubscriptionService();
      expect(sub.tier, SubscriptionPlanTier.free);
      expect(sub.isSubscribed, isFalse);
      expect(sub.isPro, isFalse);
    });
  });

  testWidgets('PaywallScreen renders tiers and test card copy button', (WidgetTester tester) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: PaywallScreen(
          state: state,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and plan tiers
    expect(find.text('STILLWATER SOVEREIGN SUITE'), findsOneWidget);
    expect(find.text('All-Access Membership'), findsOneWidget);
    expect(find.text('Community Free'), findsOneWidget);
    expect(find.text('Standard Suite'), findsOneWidget);
    expect(find.text('Pro Sovereign'), findsOneWidget);
    expect(find.text('£9.99'), findsOneWidget);
    expect(find.text('£29.99'), findsOneWidget);

    // Verify Stripe test mode helper button
    expect(find.text('Stripe Test Mode (GB)'), findsOneWidget);
    expect(find.text('Test Card'), findsOneWidget);
  });
}
