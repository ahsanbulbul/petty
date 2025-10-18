import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class LoginBunnyAnimation extends StatefulWidget {
  const LoginBunnyAnimation({super.key});

  @override
  LoginBunnyAnimationState createState() => LoginBunnyAnimationState();
}

class LoginBunnyAnimationState extends State<LoginBunnyAnimation> {
  StateMachineController? _controller;
  SMITrigger? _successTrigger;
  SMITrigger? _failTrigger;

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(artboard, 'LoginMachine');
    if (_controller != null) {
      artboard.addController(_controller!);
      _successTrigger = _controller!.findInput<bool>('login_success') as SMITrigger?;
      _failTrigger = _controller!.findInput<bool>('login_fail') as SMITrigger?;
    }
  }

  void showSuccess() {
    _successTrigger?.fire();
  }

  void showFail() {
    _failTrigger?.fire();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: RiveAnimation.asset(
        'assets/rive/bunny_animation.riv',
        onInit: _onRiveInit,
        fit: BoxFit.contain,
      ),
    );
  }
}
