import 'package:flutter/material.dart';

import 'core/auth/token_store.dart';
import 'features/pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // نقرأ التوكنات المحفوظة عشان الجلسة تفضل شغالة بعد قفل التطبيق.
  await TokenStore.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home:SplashScreen(),
    );
  }
}



