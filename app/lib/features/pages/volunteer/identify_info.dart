import 'package:flutter/material.dart';
import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../widgets/volunteerwidgets.dart';
import 'EmailVerficayion.dart';
import 'phoneverfication.dart';
import 'selfiescreen.dart';

class IdentityIntroScreen extends StatefulWidget {
  const IdentityIntroScreen({super.key});

  @override
  State<IdentityIntroScreen> createState() => _IdentityIntroScreenState();
}

class _IdentityIntroScreenState extends State<IdentityIntroScreen> {
  bool _busy = false;

  /// بيقرا حالة التحقق من الباك ويبدأ من أول خطوة ناقصة
  /// (الموبايل بيتأكد أصلاً في التسجيل، فمش بنطلبه تاني).
  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    Widget next;
    try {
      final v = await ProfileApi.instance.verification();
      final done = v.completedSteps;
      if (!done.contains('email')) {
        next = const EmailVerificationScreen();
      } else if (!done.contains('phone')) {
        next = const PhoneVerificationScreen();
      } else {
        next = const SelfieScreen();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      scrollable: false,
      bottom: VButton(
        title: 'ابدأ التحقق',
        onPressed: _busy ? null : _start,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const AssetOrIcon(
            asset: 'assets/idintity.png',
            fallback: Icons.verified_user_outlined,
            size: 150,
          ),
          const SizedBox(height: 19),
          Text(
            'ليه محتاجين نتحقق\nمن هويتك ؟',
            textAlign: TextAlign.center,
            style: vText(size: 24, weight: FontWeight.w700, height: 1.5, color: AppColors.PremaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'لضمان سلامة الجميع وحماية حقوقك',
            textAlign: TextAlign.center,
            style: vText(size: 13, color: AppColors.PremaryText),
          ),
        ],
      ),
    );
  }
}
