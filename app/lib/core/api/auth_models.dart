/// استجابة الخطوة الأولى من التسجيل: الحساب لسه ما اتعملش،
/// لازم نكمل بـ register/complete بالتذكرة + كود الـ OTP.
class PendingRegistration {
  PendingRegistration({
    required this.registrationTicket,
    required this.expiresAt,
    this.phone,
    this.requiresPhoneVerification = true,
  });

  factory PendingRegistration.fromJson(Map<String, dynamic> json) =>
      PendingRegistration(
        registrationTicket: json['registrationTicket'] as String? ?? '',
        expiresAt:
            DateTime.tryParse(json['expiresAt'] as String? ?? '')?.toLocal() ??
                DateTime.now(),
        phone: json['phone'] as String?,
        requiresPhoneVerification:
            json['requiresPhoneVerification'] as bool? ?? true,
      );

  final String registrationTicket;
  final DateTime expiresAt;
  final String? phone;
  final bool requiresPhoneVerification;
}

/// استجابة تسجيل الدخول / إكمال التسجيل / refresh.
class AuthResult {
  AuthResult({
    required this.userId,
    required this.role,
    required this.accountStatus,
    this.email,
    this.emailVerified = false,
    this.phone,
    this.phoneVerified = false,
    this.displayName,
    this.accessToken,
    this.accessTokenExpiresAt,
    this.refreshToken,
    this.refreshTokenExpiresAt,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) => AuthResult(
        userId: json['userId'] as String? ?? '',
        role: json['role'] as String? ?? '',
        accountStatus: json['accountStatus'] as String? ?? '',
        email: json['email'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
        phone: json['phone'] as String?,
        phoneVerified: json['phoneVerified'] as bool? ?? false,
        displayName: json['displayName'] as String?,
        accessToken: json['accessToken'] as String?,
        accessTokenExpiresAt:
            DateTime.tryParse(json['accessTokenExpiresAt'] as String? ?? '')
                ?.toLocal(),
        refreshToken: json['refreshToken'] as String?,
        refreshTokenExpiresAt:
            DateTime.tryParse(json['refreshTokenExpiresAt'] as String? ?? '')
                ?.toLocal(),
      );

  final String userId;
  final String role;
  final String accountStatus;
  final String? email;
  final bool emailVerified;
  final String? phone;
  final bool phoneVerified;
  final String? displayName;
  final String? accessToken;
  final DateTime? accessTokenExpiresAt;
  final String? refreshToken;
  final DateTime? refreshTokenExpiresAt;
}

/// بيانات الجلسة الحالية من GET /auth/session (من غير توكنات).
class SessionInfo {
  SessionInfo({
    required this.userId,
    required this.role,
    required this.accountStatus,
    this.email,
    this.emailVerified = false,
    this.phone,
    this.phoneVerified = false,
    this.displayName,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) => SessionInfo(
        userId: json['userId'] as String? ?? '',
        role: json['role'] as String? ?? '',
        accountStatus: json['accountStatus'] as String? ?? '',
        email: json['email'] as String?,
        emailVerified: json['emailVerified'] as bool? ?? false,
        phone: json['phone'] as String?,
        phoneVerified: json['phoneVerified'] as bool? ?? false,
        displayName: json['displayName'] as String?,
      );

  final String userId;
  final String role;
  final String accountStatus;
  final String? email;
  final bool emailVerified;
  final String? phone;
  final bool phoneVerified;
  final String? displayName;
}

/// نتيجة POST /auth/google: يا دخول ناجح، يا محتاج إكمال بيانات
/// (نوع الحساب + موبايل)، يا محتاج تحقق OTP على الموبايل.
class GoogleAuthResult {
  GoogleAuthResult({
    this.auth,
    this.registrationRequired,
    this.phoneVerificationRequired,
  });

  factory GoogleAuthResult.fromJson(Map<String, dynamic> json) {
    final authJson = (json['auth'] as Map?)?.cast<String, dynamic>();
    final regJson =
        (json['registrationRequired'] as Map?)?.cast<String, dynamic>();
    final pendingJson =
        (json['phoneVerificationRequired'] as Map?)?.cast<String, dynamic>();
    return GoogleAuthResult(
      auth: authJson == null ? null : AuthResult.fromJson(authJson),
      registrationRequired: regJson == null
          ? null
          : GoogleRegistrationRequired.fromJson(regJson),
      phoneVerificationRequired: pendingJson == null
          ? null
          : PendingRegistration.fromJson(pendingJson),
    );
  }

  final AuthResult? auth;
  final GoogleRegistrationRequired? registrationRequired;
  final PendingRegistration? phoneVerificationRequired;
}

/// رد الباك لما حساب جوجل جديد يحتاج يكمل بيانات التسجيل.
class GoogleRegistrationRequired {
  GoogleRegistrationRequired({
    required this.registrationTicket,
    required this.email,
    this.name,
    this.availableRoles = const [],
  });

  factory GoogleRegistrationRequired.fromJson(Map<String, dynamic> json) =>
      GoogleRegistrationRequired(
        registrationTicket: json['registrationTicket'] as String? ?? '',
        email: json['email'] as String? ?? '',
        name: json['name'] as String?,
        availableRoles: (json['availableRoles'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  final String registrationTicket;
  final String email;
  final String? name;
  final List<String> availableRoles;
}
