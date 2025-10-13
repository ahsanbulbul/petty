import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'app.dart'; // <-- import lightTheme, darkTheme, themeProvider
import 'theme/app_theme.dart'; // <-- required for lightTheme & darkTheme

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
    authCallbackUrlHostname: null, // required for mobile redirect
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

  @override
  void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;

    // Listen for OAuth redirect session
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        setState(() {
          _user = session.user;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider); // <-- watch themeProvider

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode, // <-- apply theme mode
      home: _user != null ? const HomeScreen() : const LoginScreen(),
    );
  }
}
