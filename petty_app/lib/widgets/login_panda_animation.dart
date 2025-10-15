import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginPandaAnimation extends StatefulWidget {
  final VoidCallback? onInitComplete;

  const LoginPandaAnimation({super.key, this.onInitComplete});

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

  bool get isReady => _controller != null;

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(artboard, 'Login Machine');
    if (_controller != null) {
      artboard.addController(_controller!);

      _isChecking = _controller!.findInput<bool>('isChecking') as SMIBool?;
      _isHandsUp = _controller!.findInput<bool>('isHandsUp') as SMIBool?;
      _numLook = _controller!.findInput<double>('numLook') as SMINumber?;
      _trigSuccess = _controller!.findInput<bool>('trigSuccess') as SMITrigger?;
      _trigFail = _controller!.findInput<bool>('trigFail') as SMITrigger?;

      widget.onInitComplete?.call();
    }
  }

  // Control methods
  void handsUp(bool value) => _isHandsUp?.value = value;
  void startChecking() => _isChecking?.value = true;
  void stopChecking() => _isChecking?.value = false;
  void lookAt(double number) => _numLook?.value = number;
  void showSuccess() => _trigSuccess?.fire();
  void showFail() => _trigFail?.fire();

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context).brightness == Brightness.light
        ? Colors.green[50]
        : Colors.grey[900];

   return Container(
  width: double.infinity,
  height: 240,
  decoration: BoxDecoration(
    color: bgColor,
    borderRadius: BorderRadius.circular(16),
  ),
  child: Transform.translate(
    offset: const Offset(0, 80), // move panda 30 pixels down
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: RiveAnimation.asset(
        'assets/rive/panda_2_animation.riv',
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    ),
  ),
);


  }
}
