import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/features/auth/screens/feature_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/home_screen.dart';
import 'features/auth/screens/reset_password_screen.dart';
import 'features/pet_adoption/presentation/pages/pet_adoption_home_page.dart';
import 'features/pet_adoption/presentation/pages/add_pet_screen.dart';
import 'features/pet_adoption/presentation/pages/adoption_requests_page.dart';
import 'features/pet_adoption/presentation/pages/my_pet_requests_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://pmxyeihahwudrrgczkou.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBteHllaWhhaHd1ZHJyZ2N6a291Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3MzEzNTUsImV4cCI6MjA3NTMwNzM1NX0.5BC6IcPLY7rAr2cFAG4T-vBkXU7sYXo5lg8xIubSjkw',
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
    // 🔹 Correct way: watch the provider, returns ThemeMode directly
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Petty App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode, // <-- Use it directly
      home: Builder(
        builder: (context) {
          if (_deepLinkToken != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                builder: (_) => ResetPasswordScreen(
                  accessToken: _deepLinkToken!,
                  onPasswordUpdated: () {
                    setState(() {
                      _deepLinkToken = null;
                    });
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
              ));
            });
          }

          return _user == null ? const LoginScreen() : const FeatureSelectionScreen();
        },
      ),
      routes: {
        '/pet_home': (context) => const PetAdoptionHomePage(),
        '/add_pet': (context) => const AddPetScreen(),
        '/my_requests': (context) => const AdoptionRequestsPage(),
        '/my_pet_requests': (context) => const MyPetRequestsPage(),
      },
    );
  }
}
