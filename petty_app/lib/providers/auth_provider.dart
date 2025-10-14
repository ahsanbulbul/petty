import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(SupabaseService.currentUser != null);

  // UPDATED: return bool
  Future<bool> login(String email, String password) async {
    try {
      await SupabaseService.signIn(email, password);
      state = true;
      return true; // login succeeded
    } catch (e) {
      state = false;
      return false; // login failed
    }
  }

  // UPDATED: return bool
  Future<bool> signup(String email, String password) async {
    try {
      await SupabaseService.signUp(email, password);
      state = true;
      return true;
    } catch (e) {
      state = false;
      return false;
    }
  }

  // loginWithGoogle can remain void, since we handle navigation via onAuthStateChange
  Future<void> loginWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle();
      state = true;
    } catch (e) {
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
