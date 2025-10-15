import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'forgot_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;
  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final otpController = TextEditingController();
  bool isLoading = false;

  Future<void> _verifyOtp() async {
    final otp = otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await Supabase.instance.client.auth.verifyOTP(
        type: OtpType.email,
        token: otp,
        email: widget.email,
      );

      if (res.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP verified successfully!")),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid OTP or expired.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error verifying OTP: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("OTP sent to ${widget.email}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _verifyOtp,
                    child: const Text("Verify OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}
