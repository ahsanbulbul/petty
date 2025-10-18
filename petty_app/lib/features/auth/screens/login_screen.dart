import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/custom_button.dart';
import '../widgets/login_panda_animation.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';
// import 'home_screen.dart';
import 'forgot_password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/features/auth/screens/home_screen.dart';


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

    // Panda reacts to password focus
    _passwordFocus.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null || !panda.isReady) return;
      panda.handsUp(_passwordFocus.hasFocus);
    });

    // Panda reacts to email typing
    emailController.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null || !panda.isReady) return;
      panda.startChecking();
      panda.lookAt(emailController.text.length.toDouble());
    });

    _emailFocus.addListener(() {
      final panda = _pandaKey.currentState;
      if (panda == null || !panda.isReady) return;
      if (!_emailFocus.hasFocus) panda.stopChecking();
    });

    // Supabase auth listener
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
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
    final panda = _pandaKey.currentState;
    if (panda == null || !panda.isReady) return;

    try {
      final success =
          await ref.read(authProvider.notifier).login(email, password);

      if (success) {
        panda.showSuccess();
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        panda.showFail();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed!")),
        );
      }
    } catch (e) {
      panda.showFail();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: $e")),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final textFieldWidth = screenWidth * 0.85;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LoginPandaAnimation(key: _pandaKey),
                      const SizedBox(height: 70),
                      SizedBox(
                        width: textFieldWidth,
                        child: CustomTextField(
                          hint: "Email",
                          controller: emailController,
                          focusNode: _emailFocus,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: textFieldWidth,
                        child: CustomTextField(
                          hint: "Password",
                          controller: passwordController,
                          obscureText: true,
                          focusNode: _passwordFocus,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Open password reset flow
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text("Forgot Password?"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            text: "Login",
                            onPressed: _login,
                          ),
                    const SizedBox(height: 1),
                    IconButton(
                      onPressed: () async {
                        try {
                          await ref
                              .read(authProvider.notifier)
                              .loginWithGoogle();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text("Google sign-in failed: $e")),
                          );
                        }
                      },
                      icon: Image.asset(
                        'assets/images/google.png',
                        height: 32,
                        width: 32,
                      ),
                    ),
                    const SizedBox(height: 1),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupScreen()),
                        );
                      },
                      child: const Text("Don't have an account? Sign Up"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
