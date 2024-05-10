import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'WebViewPage.dart';

class SplashScreenPage extends StatefulWidget {
  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(duration: Duration(seconds: 3), vsync: this);

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Animation has completed, navigate to the next page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebViewPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
            opacity: _animation,
            child: Image.asset(
              'assets/images/splash_logo.png',
              height: 120,
              width: 120,
            )),
      ),
    );
  }
}
