import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  /// Email/Password Sign Up
  static Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(email: email, password: password);
  }

  /// Email/Password Sign In
  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  /// Google Sign-In for Flutter Web
  static Future<void> signInWithGoogle() async {
  await client.auth.signInWithOAuth(
    Provider.google,
    redirectTo: 'io.supabase.flutter://login-callback', 
    // Do NOT set redirectTo; Supabase Web handles it automatically
  );
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
