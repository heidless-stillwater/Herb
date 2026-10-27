import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_options.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/main_scaffold.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/paywall_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceElevation1,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const HerbApp());
}

class HerbApp extends StatefulWidget {
  const HerbApp({super.key});

  @override
  State<HerbApp> createState() => _HerbAppState();
}

class _HerbAppState extends State<HerbApp> {
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        Widget homeWidget;
        if (!_appState.authService.isAuthenticated && !_appState.bypassAuth) {
          homeWidget = AuthGateScreen(state: _appState);
        } else if (_appState.needsPaywall) {
          homeWidget = PaywallScreen(
            state: _appState,
            onCompleted: () => _appState.setPassedPaywall(true),
          );
        } else {
          homeWidget = MainScaffold(state: _appState);
        }

        return MaterialApp(
          title: 'herb — Ritual & Telemetry',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          home: homeWidget,
        );
      },
    );
  }
}
