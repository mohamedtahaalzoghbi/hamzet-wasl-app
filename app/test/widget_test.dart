import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:graduation_project/main.dart';
import 'package:graduation_project/features/pages/splash_screen.dart';
import 'package:graduation_project/features/pages/onboarding.dart';

void main() {
  testWidgets('App starts on splash then moves to onboarding',
      (WidgetTester tester) async {
    // مقاس شاشة موبايل حقيقي (الافتراضي 800x600 بيعمل overflow في onboarding).
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);

    // السبلاش بينقل لشاشة الـ onboarding بعد 3 ثواني.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
