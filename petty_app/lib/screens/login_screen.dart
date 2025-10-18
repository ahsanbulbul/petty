import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rive/rive.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

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
                SizedBox(
                  height: 200,
                  child: const RiveAnimation.asset('assets/rive/login_animation.riv'),
                ),
                const SizedBox(height: 20),
                CustomTextField(hint: "Email", controller: emailController),
                const SizedBox(height: 15),
                CustomTextField(
                  hint: "Password",
                  controller: passwordController,
                  obscureText: true,
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
                        onPressed: () async {
                          await ref
                              .read(authProvider.notifier)
                              .login(emailController.text.trim(), passwordController.text.trim());
                          if (ref.read(authProvider)) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const HomeScreen()),
                            );
                          }
                        },
                      ),
                const SizedBox(height: 10),
                // CustomButton(
                //   text: "Sign in with Google",
                //   onPressed: () async {
                //     await ref.read(authProvider.notifier).loginWithGoogle();
                //     if (ref.read(authProvider)) {
                //       Navigator.pushReplacement(
                //         context,
                //         MaterialPageRoute(builder: (_) => const HomeScreen()),
                //       );
                //     }
                //   },
                // ),
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
