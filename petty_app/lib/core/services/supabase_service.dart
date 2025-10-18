import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import '../config/env.dart';

class SupabaseService {
  // Initialization
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  }

  // Supabase client
  static SupabaseClient get client => Supabase.instance.client;

  // Current user
  static User? get currentUser => client.auth.currentUser;

  /// Email/Password Sign Up
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  /// Email/Password Sign In
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Google Sign-In (Web + Android)
  static Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // Web flow (Supabase handles redirect automatically)
      await client.auth.signInWithOAuth(Provider.google);
    } else {
      // Android flow (deep link redirect)
      await client.auth.signInWithOAuth(
        Provider.google,
        redirectTo: 'io.supabase.flutter://login-callback', // must match AndroidManifest
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    }
  }

  /// Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  /// Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }
}
