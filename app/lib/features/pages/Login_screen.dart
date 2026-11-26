
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/auth/token_store.dart';
import '../../widgets/auth_widgets.dart';
import 'google_auth_flow.dart';
import '../../widgets/google_auth_button.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'package:graduation_project/widgets/Colors.dart';

const Color primaryColor = Color(0xFF174F50);



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool showError = false;
  bool busy = false;
  String? serverError;

  final _authApi = AuthApi.instance;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (busy) return;

    setState(() {
      showError = true;
      serverError = null;
    });

    // الباك بيقبل إيميل أو رقم موبايل في نفس الحقل.
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      return;
    }

    setState(() {
      busy = true;
    });

    try {
      final auth = await _authApi.login(
        emailOrPhone: emailController.text.trim(),
        password: passwordController.text,
      );
      await TokenStore.instance.save(auth);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        serverError = e.message;
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

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 27,
                  vertical: 18.5,
                ),

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
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

                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: 40),


                 const Text(
                  'سجل دخولك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: AppColors.textPremary,
                  ),
                ),


              const SizedBox(height: 10),

              authLabel('الإيميل أو رقم الموبايل'),
              const SizedBox(height: 8),

              authField(
                controller: emailController,
                hint: 'name@example.com أو 01xxxxxxxxx',
                icon: Icons.mark_email_read_outlined,
                keyboardType: TextInputType.emailAddress,
                error: showError && emailController.text.isEmpty,
              ),

              const SizedBox(height: 8),

              authLabel('كلمة السر'),
              const SizedBox(height: 8),

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
                      color: AppColors.PremaryText,
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

              if (showError)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    serverError ??
                        'تأكد من إدخال البريد الإلكتروني وكلمة السر بشكل صحيح',
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.errorColor,
                    ),
                  ),
                ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'نسيت كلمة السر؟',
                    style: TextStyle(
                      fontFamily: 'SemiBold',
                      color: AppColors.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 34),

              authPrimaryButton(
                title: busy ? 'جاري تسجيل الدخول...' : 'التالي',
                onPressed: login,
              ),

              const SizedBox(height: 32),

              authOrDivider(),

              const SizedBox(height: 30.75),

              GoogleAuthButton(
                onIdToken: (idToken) => handleGoogleIdToken(context, idToken),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SignUpScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'إنشاء حساب',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                        color: AppColors.PremaryText,
                      ),
                    ),
                  ),
                  const Text(
                    'ليس لديك حساب؟ ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: AppColors.graynewacount,
                    ),
                  ),


                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

