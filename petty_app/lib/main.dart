import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'app.dart'; // themeProvider
import 'core/theme/app_theme.dart'; // lightTheme & darkTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
    authCallbackUrlHostname: null,
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

    // Listen for auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _user = session?.user;
      });
    });

    // Handle incoming password recovery links
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
    final themeMode = ref.watch(themeProvider);

    // Show ResetPasswordScreen if recovery token exists
    if (_deepLinkToken != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: ResetPasswordScreen(
          accessToken: _deepLinkToken!,
          onPasswordUpdated: () {
            setState(() {
              _deepLinkToken = null;
              _user = null;
            });
          },
        ),
      );
    }

    // Normal flow
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: _user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
