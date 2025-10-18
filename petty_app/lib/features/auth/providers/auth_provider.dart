import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petty_app/core/services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(SupabaseService.currentUser != null);

  Future<bool> login(String email, String password) async {
    try {
      final response = await SupabaseService.signIn(email, password);
      
      // Check if user session exists
      if (response.session != null && response.user != null) {
        state = true;
        return true;
      } else {
        state = false;
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      state = false;
      return false;
    }
  }

  Future<bool> signup(String email, String password) async {
    try {
      final response = await SupabaseService.signUp(email, password);
      
      // Important: Supabase signup may succeed but user needs to confirm email
      // In this case, user object exists but session might be null
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.session == null) {
          // Email confirmation required - don't set state to true
          print('Signup successful - Email confirmation required');
          state = false;
          return true; // Return true because signup succeeded
        } else {
          // Auto-login succeeded (email confirmation disabled)
          state = true;
          return true;
        }
      } else {
        state = false;
        return false;
      }
    } catch (e) {
      print('Signup error: $e');
      state = false;
      return false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle();
      state = true;
    } catch (e) {
      state = false;
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await SupabaseService.resetPassword(email);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    state = false;
  }
}