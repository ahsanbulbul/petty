import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Google Sign-In for Flutter Web
  static Future<void> signInWithGoogle() async {
    await client.auth.signInWithOAuth(
      Provider.google,
      redirectTo: 'io.supabase.flutter://login-callback',
      // For web, Supabase handles redirect automatically
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