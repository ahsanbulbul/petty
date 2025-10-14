import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginPandaAnimation extends StatefulWidget {
  const LoginPandaAnimation({super.key});

  @override
  LoginPandaAnimationState createState() => LoginPandaAnimationState();
}

class LoginPandaAnimationState extends State<LoginPandaAnimation> {
  StateMachineController? _controller;
  SMIBool? _isChecking;
  SMIBool? _isHandsUp;
  SMINumber? _numLook;
  SMITrigger? _trigSuccess;
  SMITrigger? _trigFail;

  void _onRiveInit(Artboard artboard) {
    // Make sure this matches exactly the State Machine name in Rive
    _controller = StateMachineController.fromArtboard(artboard, 'Login Machine'); // no spaces
    if (_controller != null) {
      artboard.addController(_controller!);

      // Bind inputs from state machine
      _isChecking = _controller!.findInput<bool>('isChecking') as SMIBool?;
      _isHandsUp = _controller!.findInput<bool>('isHandsUp') as SMIBool?;
      _numLook = _controller!.findInput<double>('numLook') as SMINumber?;
      _trigSuccess = _controller!.findInput<bool>('trigSuccess') as SMITrigger?;
      _trigFail = _controller!.findInput<bool>('trigFail') as SMITrigger?;
    }
  }

  // Public methods to control animation
  void handsUp(bool value) => _isHandsUp?.value = value;
  void startChecking() => _isChecking?.value = true;
  void stopChecking() => _isChecking?.value = false;
  void lookAt(double number) => _numLook?.value = number;
  void showSuccess() => _trigSuccess?.fire();
  void showFail() => _trigFail?.fire();

  @override
  Widget build(BuildContext context) {
    // Theme-aware background
    final bgColor = Theme.of(context).brightness == Brightness.light
        ? Colors.green[50]
        : Colors.grey[900];

    // Responsive size
    final size = MediaQuery.of(context).size.width * 1;

    // Return the container wrapping the Panda animation
    return SizedBox(
      width: double.infinity,
      height: 220,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: SizedBox(
            width: size,
            height: size,
            child: RiveAnimation.asset(
              'assets/rive/panda_animation.riv',
              fit: BoxFit.contain,
              onInit: _onRiveInit,
            ),
          ),
        ),
      ),
    );
  }
}
