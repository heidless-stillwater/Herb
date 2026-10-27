import 'package:flutter_test/flutter_test.dart';
import 'package:herb_app/screens/auth_gate_screen.dart';
import 'package:herb_app/state/app_state.dart';
import 'package:herb_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('AuthGateScreen renders and toggles between Sign In and Create Account', (WidgetTester tester) async {
    final state = AppState();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: AuthGateScreen(state: state),
      ),
    );
    await tester.pumpAndSettle();

    // Default mode: Sign In
    expect(find.text('STILLWATER SOVEREIGN SUITE'), findsOneWidget);
    expect(find.text('Suite Authentication'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.text('Sign In to Stillwater Suite'), findsOneWidget);
    expect(find.text('Continue in Offline / Local Mode'), findsOneWidget);
    expect(find.text("Don't have an account? Create one"), findsOneWidget);

    // Switch to Create Account mode via segmented pill
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('Create Sovereign Account'), findsNWidgets(2)); // Title & Button
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Already have a Suite account? Sign In'), findsOneWidget);

    // Switch back to Sign In
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.text('Suite Authentication'), findsOneWidget);
    expect(find.text('Confirm Password'), findsNothing);
  });
}
