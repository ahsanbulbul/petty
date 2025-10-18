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
      if (response.user != null) {
        if (response.session == null) {
          print('Signup successful - Email confirmation required');
          state = false;
          return true;
        } else {
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
      print("Google login error: $e");
      state = false;
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await SupabaseService.resetPassword(email);
  }

  Future<void> logout() async {
    await SupabaseService.signOut();
    state = false;
  }
}
