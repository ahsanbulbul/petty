import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/features/auth/screens/splash_screen.dart';
import 'package:petty_app/features/auth/screens/login_screen.dart';
import 'package:petty_app/features/auth/screens/feature_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/screens/reset_password_screen.dart';

// Create a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  User? _user;
  String? _deepLinkToken;

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _user = session?.user;
      });
    });

    _handleInitialDeepLink();
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final appLinks = AppLinks();
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null) {
        final type = initialUri.queryParameters['type'];
        final token = initialUri.queryParameters['access_token'];
        if (type == 'recovery' && token != null) {
          setState(() {
            _deepLinkToken = token;
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      navigatorKey: navigatorKey, // assign the global key
      debugShowCheckedModeBanner: false,
      title: 'Petty App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: SplashScreen(
        onSplashCompleted: () {
          // Navigate using the global navigator key
          if (_deepLinkToken != null) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  accessToken: _deepLinkToken!,
                  onPasswordUpdated: () {
                    _deepLinkToken = null;
                    navigatorKey.currentState?.pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ),
            );
          } else if (_user != null) {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const FeatureSelectionScreen()),
            );
          } else {
            navigatorKey.currentState?.pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          }
        },
      ),
    );
  }
}
