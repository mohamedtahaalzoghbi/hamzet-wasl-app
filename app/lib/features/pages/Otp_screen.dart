import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/Colors.dart';
import '../../widgets/auth_widgets.dart';
import 'AccountSuccessScreen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.target,
    this.isPhone = false,
    this.onVerified,
    this.verifyCode,
    this.resendCode,
  });

  /// الإيميل أو رقم الموبايل اللي اتبعت له الكود (بيتعرض في النص).
  final String? target;

  /// true = الكود اتبعت SMS، false = اتبعت على الإيميل.
  final bool isPhone;

  /// بتتنادى بعد ما الكود يتأكد. لو null بنروح لـ AccountSuccessScreen.
  final void Function(BuildContext context)? onVerified;

  /// التحقق من الكود على الباك. ترجع null لو الكود صح، أو رسالة الخطأ لو غلط.
  /// لو null (لسه مفيش ربط) الكود بيتقبل محليًا زي قبل.
  final Future<String?> Function(String code)? verifyCode;

  /// إعادة إرسال الكود على الباك. ترجع null لو تمت، أو رسالة الخطأ.
  final Future<String?> Function()? resendCode;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> controllers =
  List.generate(6, (_) => TextEditingController());

  final List<FocusNode> focusNodes =
  List.generate(6, (_) => FocusNode());

  bool showError = false;
  bool busy = false;
  String? serverError;

  String get otpCode =>
      controllers.map((controller) => controller.text).join();

  String get message {
    if (widget.isPhone) {
      return 'تحقق من رسائل SMS. لقد أرسلنا رمز تحقق لمرة واحدة إلى الرقم '
          '${widget.target ?? ''}. أدخل الرمز أدناه للتحقق من حسابك.';
    }
    if (widget.target != null) {
      return 'تم إرسال رمز التحقق إلى ${widget.target}.\n'
          'من فضلك أدخل الرمز المكون من 6 أرقام.';
    }
    return 'تم إرسال رمز التحقق إلى بريدك الإلكتروني.\n'
        'من فضلك أدخل الرمز المكون من 6 أرقام.';
  }

  @override
  void dispose() {
    for (final controller in controllers) {
      controller.dispose();
    }

    for (final node in focusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> verifyOtp() async {
    if (busy) return;
    if (otpCode.length != 6) {
      setState(() {
        showError = true;
        serverError = null;
      });
      return;
    }

    // لو الشاشة مربوطة بالباك نتحقق من الكود عليه الأول.
    if (widget.verifyCode != null) {
      setState(() {
        busy = true;
        showError = false;
        serverError = null;
      });
      String? error;
      try {
        error = await widget.verifyCode!(otpCode);
      } catch (_) {
        error = 'مشكلة في الاتصال بالسيرفر. حاول تاني.';
      }
      if (!mounted) return;
      setState(() {
        busy = false;
        serverError = error;
        showError = error != null;
      });
      if (error != null) return;
    } else {
      debugPrint('OTP: $otpCode');
    }

    if (widget.onVerified != null) {
      widget.onVerified!(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountSuccessScreen()),
      );
    }
  }

  Future<void> resendOtp() async {
    if (busy) return;

    for (final controller in controllers) {
      controller.clear();
    }
    FocusScope.of(context).requestFocus(focusNodes[0]);

    if (widget.resendCode == null) {
      setState(() {
        showError = false;
        serverError = null;
      });
      return;
    }

    setState(() {
      busy = true;
      showError = false;
      serverError = null;
    });
    String? error;
    try {
      error = await widget.resendCode!();
    } catch (_) {
      error = 'مشكلة في الاتصال بالسيرفر. حاول تاني.';
    }
    if (!mounted) return;
    setState(() {
      busy = false;
      serverError = error;
      showError = error != null;
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز تحقق جديد')),
      );
    }
  }

  Widget otpBox(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: 35,
        height: 51,
        child: TextField(
          controller: controllers[index],
          focusNode: focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: const Color(0xFFF1F2F5),
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: BorderSide(
                color: showError && controllers[index].text.isEmpty
                    ? authErrorColor
                    : Colors.transparent,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                color: authPrimaryColor,
                width: 1.2,
              ),
            ),
          ),
          onChanged: (value) {
            setState(() {
              showError = false;
            });

            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context).requestFocus(
                focusNodes[index + 1],
              );
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).requestFocus(
                focusNodes[index - 1],
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(flex: 2),

              const Text(
                '(OTP) ادخل رمز التحقق ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: authTextColor,
                ),
              ),

              const SizedBox(height: 25),

              Text(
                message,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  color: AppColors.TextPremaryLight,
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                      (index) => otpBox(index),
                ),
              ),

              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    serverError ?? 'يرجى إدخال رمز التحقق كاملًا',
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 11,
                      color: authErrorColor,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              authPrimaryButton(
                title: busy ? 'جاري التحقق...' : 'ابدأ التحقق',
                onPressed: verifyOtp,
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: resendOtp,
                child: Text(
                  'لم يصلك رمز (OTP)؟ أعد إرسال رمز التحقق.',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    color: AppColors.TextPremaryLight,
                  ),
                ),
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

