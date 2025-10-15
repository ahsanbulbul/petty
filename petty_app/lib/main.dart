import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart'; // ✅ replaced uni_links
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/reset_password_screen.dart';
import 'app.dart'; // lightTheme, darkTheme, themeProvider
import 'theme/app_theme.dart'; // lightTheme & darkTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
    authCallbackUrlHostname: null, // for mobile deep link
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

    // Listen for auth state changes (login/logout)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      setState(() {
        _user = session?.user;
      });
    });

    // Handle deep link when app opens via Magic Link using app_links
    _handleInitialDeepLink();
  }

  Future<void> _handleInitialDeepLink() async {
    try {
      final appLinks = AppLinks();
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null && initialUri.queryParameters.containsKey('access_token')) {
        setState(() {
          _deepLinkToken = initialUri.queryParameters['access_token'];
        });
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    // If Magic Link token exists → open ResetPasswordScreen
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

    // Normal app flow
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: _user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
