
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/auth/token_store.dart';
import '../../core/usersection.dart';
import '../../widgets/Colors.dart';
import '../../widgets/auth_widgets.dart';
import 'Otp_screen.dart';
import 'google_auth_flow.dart';
import '../../widgets/google_auth_button.dart';



class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool agreeTerms = false;
  bool showError = false;
  bool busy = false;
  String? serverError;

  final _authApi = AuthApi.instance;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  /// ربط نوع الحساب في الشاشات بنوع الحساب في الباك.
  static String? get _backendRole {
    switch (UserSession.accountKind) {
      case AccountKind.volunteer:
        return 'volunteer';
      case AccountKind.company:
        return 'company';
      case AccountKind.organization:
        return 'association';
      case AccountKind.interested:
        return 'disabled_user';
      case null:
        return null;
    }
  }

  Future<void> createAccount() async {
    if (busy) return;

    setState(() {
      showError = true;
      serverError = null;
    });

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        !emailController.text.contains('@') ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.length < 8 ||
        confirmPasswordController.text.isEmpty ||
        passwordController.text != confirmPasswordController.text ||
        !agreeTerms) {
      return;
    }

    final role = _backendRole;
    if (role == null) {
      setState(() {
        serverError = 'اختار نوع الحساب الأول';
      });
      return;
    }

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text;

    setState(() {
      busy = true;
    });

    try {
      // الخطوة 1: التحقق من البيانات وإرسال كود OTP على الموبايل.
      final pending = await _authApi.register(
        role: role,
        name: name,
        email: email,
        phone: phone,
        password: password,
        confirmPassword: confirmPasswordController.text,
        termsAccepted: agreeTerms,
        organizationName: (role == 'company' || role == 'association') ? name : null,
      );

      UserSession.email = email;
      UserSession.phone = phone;
      UserSession.registrationTicket = pending.registrationTicket;
      UserSession.registrationTicketExpiresAt = pending.expiresAt;

      if (!mounted) return;

      // الخطوة 2: شاشة الـ OTP بتكمل التسجيل بالتذكرة والكود.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            isPhone: true,
            target: pending.phone ?? phone,
            verifyCode: (code) async {
              try {
                final auth = await _authApi.completeRegistration(
                  registrationTicket: pending.registrationTicket,
                  code: code,
                );
                await TokenStore.instance.save(auth);
                return null;
              } on ApiException catch (e) {
                return e.message;
              }
            },
            resendCode: () async {
              try {
                await _authApi.resendRegistrationCode(
                  pending.registrationTicket,
                );
                return null;
              } on ApiException catch (e) {
                return e.message;
              }
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        serverError = e.fieldError('phone') ??
            e.fieldError('email') ??
            e.fieldError('password') ??
            e.message;
      });
    } catch (_) {
      setState(() {
        serverError = 'مشكلة في الاتصال بالسيرفر. حاول تاني.';
      });
    } finally {
      if (mounted) {
        setState(() {
          busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Text(
                'إنشاء حساب جديد',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppColors.textPremary,
                ),
              ),

              const SizedBox(height: 35),

              authLabel('الاسم'),


              authField(
                controller: nameController,
                hint: 'مثال: أحمد محمد',
                icon: Icons.person_outline,
                error: showError && nameController.text.isEmpty,
              ),

              const SizedBox(height: 14),

              authLabel('الإيميل'),


              authField(
                controller: emailController,
                hint: 'name@example.com',
                icon: Icons.mark_email_read_outlined,
                keyboardType: TextInputType.emailAddress,
                error: showError &&
                    (emailController.text.isEmpty ||
                        !emailController.text.contains('@')),
              ),

              const SizedBox(height: 8),

              authLabel('رقم التليفون'),


              authField(
                controller: phoneController,
                hint: '01xxxxxxxxx',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                error: showError && phoneController.text.isEmpty,
              ),

              const SizedBox(height: 14),

              authLabel('كلمة السر'),


              SizedBox(
                width: 362,
                height: 64,
                child: TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: authInputDecoration(
                    hint: 'ادخل على الأقل 8 أحرف',
                    error: showError && passwordController.text.isEmpty,
                  ).copyWith(
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.TextSecondaryLight,
                    ),
                    prefixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              authLabel('أكد كلمة السر'),

              SizedBox(
                width: 362,
                height: 64,
                child: TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  decoration: authInputDecoration(
                    hint: 'أعد كتابة كلمة المرور',
                    error: showError &&
                        (confirmPasswordController.text.isEmpty ||
                            passwordController.text !=
                                confirmPasswordController.text),
                  ).copyWith(
                    hintStyle: GoogleFonts.cairo(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.TextSecondaryLight,
                    ),
                    prefixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 19,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 20,
                    ),
                  ),
                ),
              ),


              if (showError &&
                  passwordController.text !=
                      confirmPasswordController.text)
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    'كلمتا السر غير متطابقتين',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 10,
                      color: authErrorColor,
                    ),
                  ),
                ),

              const SizedBox(height: 7),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Text(
                      'أوافق على الشروط والأحكام وسياسة الخصوصية',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF767676),
                      ),
                    ),
                  ),

                  Checkbox(
                    value: agreeTerms,
                    activeColor: authPrimaryColor,
                    onChanged: (value) {
                      setState(() {
                        agreeTerms = value ?? false;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (serverError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    serverError!,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 12,
                      color: authErrorColor,
                    ),
                  ),
                ),

              authPrimaryButton(
                title: busy ? 'جاري إنشاء الحساب...' : 'التالي',
                onPressed: createAccount,
              ),

              const SizedBox(height: 20),

              authOrDivider(),

              const SizedBox(height: 16),

              GoogleAuthButton(
                onIdToken: (idToken) => handleGoogleIdToken(
                  context,
                  idToken,
                  preselectedRole: _backendRole,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
    'سجل دخول',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.PremaryText,
                      ),
                    ),
                  ),
                  const Text(
    'عندك حساب بالفعل؟'
                    ,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppColors.graynewacount,
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}

