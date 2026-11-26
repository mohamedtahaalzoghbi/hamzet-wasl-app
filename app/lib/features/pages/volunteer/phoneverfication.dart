import 'package:flutter/material.dart';


import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/auth_api.dart';
import 'package:graduation_project/features/pages/Otp_screen.dart';
import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/usersection.dart';
import '../../../widgets/volunteerwidgets.dart';
import 'selfiescreen.dart';


class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phone = TextEditingController(text: _local(UserSession.phone));

  static String _local(String? p) {
    if (p == null) return '';
    var s = p.replaceAll(RegExp(r'[^0-9]'), '');
    if (s.startsWith('20')) s = '0${s.substring(2)}';
    return s;
  }
  bool _showError = false;
  bool _busy = false;
  String? _serverError;

  // أرقام مصرية: 010 / 011 / 012 / 015
  bool get _valid => RegExp(r'^01[0125][0-9]{8}$').hasMatch(_phone.text.trim());

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _showError = true;
      _serverError = null;
    });
    if (!_valid || _busy) return;

    UserSession.phone = _phone.text.trim();

    setState(() => _busy = true);
    try {
      // إرسال كود SMS للمستخدم المسجل دخوله.
      await AuthApi.instance.sendPhoneCode(UserSession.phone!);
    } on ApiException catch (e) {
      // لو الكود اتبعت من شوية (cooldown) نكمّل لشاشة إدخال الكود بدل ما نعلّق المستخدم.
      if (e.code != 'OTP_RESEND_TOO_SOON') {
        setState(() => _serverError = e.message);
        return;
      }
    } catch (_) {
      setState(() => _serverError = 'مشكلة في الاتصال بالسيرفر. حاول تاني.');
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpScreen(
          isPhone: true,
          target: '+2${UserSession.phone}',
          verifyCode: (code) async {
            try {
              await AuthApi.instance.verifyPhoneCode(code);
              return null;
            } on ApiException catch (e) {
              return e.message;
            }
          },
          resendCode: () async {
            try {
              await AuthApi.instance.sendPhoneCode(UserSession.phone!);
              return null;
            } on ApiException catch (e) {
              return e.message;
            }
          },
          onVerified: (ctx) => Navigator.pushReplacement(
            ctx,
            MaterialPageRoute(builder: (_) => const SelfieScreen()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'التحقق من الموبايل',
      bottom: VButton(title: 'ارسال الرمز', onPressed: _send),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Center(
            child: AssetOrIcon(
              asset: 'assets/phonever.png',
              fallback: Icons.phone_iphone,
              size: 150,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'ادخل رقم الموبايل',
              style: vText(size: 16, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'سيتم ارسال رمز التحقق الى الرقم المكتوب',
              textAlign: TextAlign.center,
              style: vText(size: 12, color: AppColors.TextSecondaryLight),
            ),
          ),
          const SizedBox(height: 20),
          VField(
            label: 'رقم التليفون',
            hint: '01xxxxxxxxx',
            controller: _phone,
            keyboardType: TextInputType.phone,
            ltr: true,
            error: _showError && !_valid,
            errorText: 'اكتب رقم موبايل مصري صحيح (11 رقم)',
            onChanged: (_) => setState(() {}),
          ),
          if (_serverError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _serverError!,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: vText(size: 12, color: AppColors.errorColor),
              ),
            ),
        ],
      ),
    );
  }
}

