import 'api_client.dart';
import 'auth_models.dart';

/// طلبات المصادقة (auth) على الباك.
/// العقد متأكد منه على السيرفر المرفوع (swagger + تجربة فعلية 25 نوفمبر 2026).
class AuthApi {
  AuthApi({ApiClient? client}) : _client = client ?? ApiClient();

  /// نسخة مشتركة بتقرأ التوكن من TokenStore للطلبات المحمية.
  static final AuthApi instance = AuthApi();

  final ApiClient _client;

  /// Sign Up - الخطوة 1: بيتحقق من البيانات ويبعت OTP على الموبايل.
  /// مش بيعمل حساب في قاعدة البيانات؛ بيرجع registrationTicket.
  Future<PendingRegistration> register({
    required String role,
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    bool termsAccepted = true,
    String? organizationName,
    String policyVersion = 'v1',
  }) async {
    final json = await _client.post('/auth/register', {
      'role': role,
      'name': name,
      if (organizationName != null) 'organizationName': organizationName,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
      'termsAccepted': termsAccepted,
      'policyVersion': policyVersion,
    });
    return PendingRegistration.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// Sign Up - الخطوة 2: بيتحقق من كود الـ OTP وبيعمل الحساب وبيرجع التوكنات.
  Future<AuthResult> completeRegistration({
    required String registrationTicket,
    required String code,
  }) async {
    final json = await _client.post('/auth/register/complete', {
      'registrationTicket': registrationTicket,
      'code': code,
    });
    return AuthResult.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// إعادة إرسال كود التسجيل لنفس التذكرة.
  Future<PendingRegistration> resendRegistrationCode(
    String registrationTicket,
  ) async {
    final json = await _client.post('/auth/register/resend', {
      'registrationTicket': registrationTicket,
    });
    final data = (json['data'] as Map?)?.cast<String, dynamic>();
    // السيرفر بيرجع success فقط في بعض الحالات؛ لو مفيش data نرجع نفس التذكرة.
    if (data == null) {
      return PendingRegistration(
        registrationTicket: registrationTicket,
        expiresAt: DateTime.now(),
      );
    }
    return PendingRegistration.fromJson(data);
  }

  /// تسجيل الدخول بالإيميل أو الموبايل + كلمة السر.
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final json = await _client.post('/auth/login', {
      'emailOrPhone': emailOrPhone,
      'password': password,
    });
    return AuthResult.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// تسجيل الدخول / بدء التسجيل بحساب جوجل عبر الـ ID token.
  /// أول نداء بالـ token بس: لو الحساب موجود بيرجع auth (دخول مباشر)،
  /// ولو جديد بيرجع registrationRequired فيه تذكرة + الأدوار المتاحة.
  /// تاني نداء بالدور + الموبايل + الموافقة + التذكرة بيرجع phoneVerificationRequired.
  Future<GoogleAuthResult> googleAuth({
    required String idToken,
    String? role,
    String? phone,
    bool termsAccepted = false,
    String? registrationTicket,
    String policyVersion = 'v1',
  }) async {
    final json = await _client.post('/auth/google', {
      'idToken': idToken,
      if (role != null) 'role': role,
      if (phone != null) 'phone': phone,
      'termsAccepted': termsAccepted,
      if (registrationTicket != null) 'registrationTicket': registrationTicket,
      'policyVersion': policyVersion,
    });
    return GoogleAuthResult.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// تدوير الـ refresh token للحصول على access token جديد.
  Future<AuthResult> refresh(String refreshToken) async {
    final json = await _client.post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthResult.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// تسجيل الخروج وإلغاء الـ refresh tokens النشطة.
  Future<void> logout() async {
    await _client.post('/auth/logout', {}, auth: true);
  }

  /// بيانات الجلسة الحالية (محمي بالتوكن).
  Future<SessionInfo> session() async {
    final json = await _client.get('/auth/session', auth: true);
    return SessionInfo.fromJson(
      (json['data'] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  /// إرسال كود تحقق SMS لمستخدم مسجل دخول (مثلاً من شاشة تحقق المتطوع).
  Future<void> sendPhoneCode(String phone) async {
    await _client.post('/auth/phone/send-code', {'phone': phone}, auth: true);
  }

  /// تأكيد كود تحقق الموبايل لمستخدم مسجل دخول.
  Future<void> verifyPhoneCode(String code) async {
    await _client.post('/auth/phone/verify', {'code': code}, auth: true);
  }

  /// إرسال كود تحقق على الإيميل لمستخدم مسجل دخول.
  Future<void> sendEmailCode() async {
    await _client.post('/auth/email/send-code', {}, auth: true);
  }

  /// تأكيد كود تحقق الإيميل لمستخدم مسجل دخول.
  Future<void> verifyEmailCode(String code) async {
    await _client.post('/auth/email/verify', {'code': code}, auth: true);
  }

  /// نسيان كلمة السر: بيبعت رمز/لينك على الإيميل لو الحساب موجود.
  Future<void> forgotPassword(String email) async {
    await _client.post('/auth/forgot-password', {'email': email});
  }

  /// تغيير كلمة السر لمستخدم مسجل دخول.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _client.post('/auth/change-password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    }, auth: true);
  }
}
