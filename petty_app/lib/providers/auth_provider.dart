import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

final authProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(SupabaseService.currentUser != null);

  Future<void> login(String email, String password) async {
    try {
      await SupabaseService.signIn(email, password);
      state = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup(String email, String password) async {
    try {
      await SupabaseService.signUp(email, password);
      state = true;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await SupabaseService.signInWithGoogle(); // await only, no return
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
