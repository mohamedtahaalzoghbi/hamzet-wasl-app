import 'package:flutter/material.dart';
import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/auth_api.dart';
import 'package:graduation_project/core/api/profile_api.dart';
import 'package:graduation_project/features/pages/volunteer/selfiescreen.dart';
import 'package:graduation_project/features/pages/Otp_screen.dart';
import 'package:graduation_project/features/pages/volunteer/phoneverfication.dart';
import 'package:graduation_project/widgets/Colors.dart';
import '../../../core/usersection.dart';
import '../../../widgets/volunteerwidgets.dart';


class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _email = TextEditingController(text: UserSession.email ?? '');
  bool _showError = false;
  bool _busy = false;
  String? _serverError;

  bool get _valid =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(_email.text.trim());

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _showError = true;
      _serverError = null;
    });
    if (!_valid || _busy) return;


    setState(() => _busy = true);
    try {
      // إرسال كود التحقق على الإيميل للمستخدم المسجل دخوله.
      await AuthApi.instance.sendEmailCode();
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
          target: UserSession.email,
          verifyCode: (code) async {
            try {
              await AuthApi.instance.verifyEmailCode(code);
              return null;
            } on ApiException catch (e) {
              return e.message;
            }
          },
          resendCode: () async {
            try {
              await AuthApi.instance.sendEmailCode();
              return null;
            } on ApiException catch (e) {
              return e.message;
            }
          },
          onVerified: (ctx) async {
            // الموبايل بيتأكد في التسجيل، فنروح للخطوة الناقصة بس.
            Widget next = const PhoneVerificationScreen();
            try {
              final v = await ProfileApi.instance.verification();
              if (v.completedSteps.contains('phone')) next = const SelfieScreen();
            } catch (_) {}
            if (!ctx.mounted) return;
            Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => next));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'التحقق من الإيميل',
      bottom: VButton(title: 'ارسال الرمز', onPressed: _send),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          const Center(
            child: AssetOrIcon(
              asset: 'assets/emailver.png',
              fallback: Icons.mark_email_unread_outlined,
              size: 150,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text('ادخل ايميلك', style: vText(size: 16, weight: FontWeight.bold,color: AppColors.PremaryText)),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'سيتم ارسال رمز التحقق الى إيميل حسابك',
              textAlign: TextAlign.center,
              style: vText(size: 16, color: AppColors.PremaryText,weight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          VField(
            label: 'الايميل',
            hint: 'name@example.com',
            controller: _email,
            readOnly: true, // الكود بيتبعت دايماً لإيميل التسجيل
            icon: Icons.mark_email_read_outlined,
            keyboardType: TextInputType.emailAddress,
            ltr: true,
            error: _showError && !_valid,
            errorText: 'اكتب إيميل صحيح',
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

