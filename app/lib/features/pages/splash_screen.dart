
import 'dart:async';
import 'package:flutter/material.dart';

import '../../widgets/Colors.dart';
import '../../core/auth/token_store.dart';
import 'home_screen.dart';
import 'onboarding.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      // لو فيه جلسة محفوظة نروح على الشاشة الرئيسية (بتتحقق من التوكن من الباك).
      final hasSession = TokenStore.instance.hasSession;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              hasSession ? const HomeScreen() : const OnboardingScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(
              'assets/BG.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Center Content
            Center(
              child: Column(

                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    width: 193,
                    height: 213,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 17),

                  Text(
                    'همزة وصل',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPremary,
                    ),
                  ),

                  SizedBox(height: 17),

                  Text(
                    'الاختلاف يجمعنا، والتعاون يقوينا',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPremary,
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const SizedBox(height: 44),

                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      strokeWidth: 5,
                      valueColor: AlwaysStoppedAnimation(
                        Color(0xFF237272),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



