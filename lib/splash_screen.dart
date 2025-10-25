import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:senior_fall_detection/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState(){
    super.initState();
      _init();
  }

  Future <void> _init() async {
    await Future.delayed(const Duration(seconds: 3));
    final user = FirebaseAuth.instance.currentUser;
    if (user != null){
      Navigator.pushReplacementNamed(context, "/home");
    }
    else {
      Navigator.pushReplacementNamed(context, "/login");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: card_color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(),
            Image.asset("assets/fall_detection_logo.png"),
            SizedBox(
              width: 213,
              height: 196,
              child: Text(
                textAlign: TextAlign.center,
                "Elder Fall Detector",
                style: TextStyle(
                  color: primary_color,
                  fontSize: 40,
                  fontFamily: "Inter"
                ),
              ),
            ),
            Spacer(),
            Text(
              "1.0.0v",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.5)
              ),
            ),
            SizedBox(height: 10)
          ],
        ),
      )




    );
  }
}
