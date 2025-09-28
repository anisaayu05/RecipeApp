import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:recipe_app/app/routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double _logoOpacity = 1.0;

  @override
  void initState() {
    super.initState();

    // Mulai animasi fade konten
    Timer(const Duration(seconds: 2), () {
      setState(() => _logoOpacity = 0.0);
    });

    // Navigasi pas bersamaan dengan fade
    Timer(const Duration(seconds: 3), _checkAuth);
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    Get.offAllNamed(user != null ? Routes.HOME : Routes.LOGIN);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background tetap gradasi → tidak putih
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF7F50), Color(0xFFFF4500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedOpacity(
            opacity: _logoOpacity,
            duration: const Duration(seconds: 1),
            curve: Curves.easeInOut,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.restaurant_menu,
                    size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  "Recipe App",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(height: 40),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

