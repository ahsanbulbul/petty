import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String accessToken;
  final VoidCallback onPasswordUpdated;

  const ResetPasswordScreen({
    super.key,
    required this.accessToken,
    required this.onPasswordUpdated,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  void _initAppLinks() async {
    final appLinks = AppLinks();
    try {
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null && initialUri.queryParameters.containsKey('access_token')) {
        // You can extract token if needed
        debugPrint('Initial access token: ${initialUri.queryParameters['access_token']}');
      }
    } catch (e) {
      debugPrint('Failed to get initial app link: $e');
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = passwordController.text.trim();
    if (newPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password cannot be empty")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await Supabase.instance.client.auth.setSession(widget.accessToken);

      final res = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully")),
        );
        widget.onPasswordUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update password")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "New Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _updatePassword,
                    child: const Text("Update Password"),
                  ),
          ],
        ),
      ),
    );
  }
}
