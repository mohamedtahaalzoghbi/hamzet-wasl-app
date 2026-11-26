
import 'package:flutter/material.dart';
import 'package:graduation_project/widgets/Colors.dart';

import 'AccountTypeScreen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;

  final List<String> images = [
    'assets/onboarding_1.png',
    'assets/onboarding_2.png',
    'assets/onboarding_3.png',
  ];

  final List<String> titles = [
    'معًا نعطي، ومعًا ننمو',
    'اختلافنا يجمعنا',
    'مجتمع ينهض بالجميع',
  ];

  final List<String> descriptions = [
    'لكل إنسان قدرة يشارك بها، ولكل مساهمة أثر يصنع فرقًا.',
    'مساحة واحدة تجمعنا، تواصل فيها نتواصل فيها و الخبرات\n والمهارات، ونكتشف قيمة ما يقدمه كل منا.',
    'نصنع فرصًا بيئة متكافئة للمشاركة والعطاء، حيث يجد كل\n شخص الدعم، ويكون لكل شخص دور وأثر.',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 27,
                vertical: 18.5,
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      if (currentPage > 0) {
                        setState(() {
                          currentPage--;
                        });
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: SizedBox(
                      width: 6,
                      height: 12,
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 15,
                        color: AppColors.IconColor_back,
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      // Navigate to Home Screen
                    },
                    child: SizedBox(
                      width: 44,
                      height: 21,

                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          color: AppColors.PremaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            Container(
              alignment: Alignment.center,
              child: Image.asset(
                images[currentPage],
                fit: BoxFit.contain,
                height: 323,
                width: 323,
              ),
            ),

            SizedBox(height: 9),

            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  titles[currentPage],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w400,
                    color: AppColors.PremaryText,
                  ),
                ),

                const SizedBox(height: 17),

                Text(
                  descriptions[currentPage],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: AppColors.PremaryText,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 84),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,color: index <= currentPage
                      ? AppColors.accessibleTerracotta
                      : AppColors.TextSecondaryDart,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),


            SizedBox(
              width: 363,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  if (currentPage < 2) {
                    setState(() {
                      currentPage++;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AccountTypeScreen(),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary_button,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  currentPage == 2 ? 'ابدأ الآن' : 'التالي',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFDF6EF),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

