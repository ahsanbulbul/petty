import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/login_panda_animation.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final GlobalKey<LoginPandaAnimationState> _pandaKey = GlobalKey();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    // Password focus triggers hands up
    _passwordFocus.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null) return;
      panda.handsUp(_passwordFocus.hasFocus);
    });

    // Email typing triggers eyes movement
    emailController.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null) return;
      panda.startChecking();
      panda.lookAt(emailController.text.length.toDouble());
    });

    // Stop checking when email is unfocused
    _emailFocus.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null) return;
      if (!_emailFocus.hasFocus) panda.stopChecking();
    });

    // Supabase auth state listener for Google login
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    });
  }

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).login(email, password);

    if (success) {
      _pandaKey.currentState?.showSuccess();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _pandaKey.currentState?.showFail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Failed!")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Panda animation
                SizedBox(
                  height: 200,
                  child: LoginPandaAnimation(key: _pandaKey),
                ),
                const SizedBox(height: 20),

                // Email
                CustomTextField(
                  hint: "Email",
                  controller: emailController,
                  focusNode: _emailFocus,
                ),
                const SizedBox(height: 15),

                // Password
                CustomTextField(
                  hint: "Password",
                  controller: passwordController,
                  obscureText: true,
                  focusNode: _passwordFocus,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      final email = emailController.text.trim();
                      if (email.isEmpty) return;
                      await ref.read(authProvider.notifier).resetPassword(email);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Password reset email sent")),
                      );
                    },
                    child: const Text("Forgot Password?"),
                  ),
                ),
                const SizedBox(height: 10),

                isLoading
                    ? const CircularProgressIndicator()
                    : CustomButton(
                        text: "Login",
                        onPressed: _login,
                      ),
                const SizedBox(height: 10),

                CustomButton(
                  text: "Sign in with Google",
                  onPressed: () async {
                    try {
                      await ref.read(authProvider.notifier).loginWithGoogle();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Google sign-in failed: $e")),
                      );
                    }
                  },
                ),
                const SizedBox(height: 15),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    );
                  },
                  child: const Text("Don't have an account? Sign Up"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
