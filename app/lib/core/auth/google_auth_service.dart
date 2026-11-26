import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

/// غلاف صغير حوالين حزمة google_sign_in:
/// - على الموبايل بنستخدم authenticate() من زرارنا المخصص.
/// - على الويب جوجل لازم ترسم الزرار بنفسها (renderButton)،
///   والنتيجة بتوصل من stream بتاع authenticationEvents.
class GoogleAuthService {
  GoogleAuthService._();

  static final GoogleAuthService instance = GoogleAuthService._();

  bool _initialized = false;
  GoogleSignInAccount? _account;

  final StreamController<GoogleSignInAccount?> _eventsController =
      StreamController<GoogleSignInAccount?>.broadcast();

  /// أحدث حساب جوجل سجل دخول في الجلسة دي.
  GoogleSignInAccount? get account => _account;

  bool get isConfigured => AppConfig.googleSignInConfigured;

  /// أحداث تسجيل الدخول (على الويب زرار جوجل بيبعت من هنا).
  Stream<GoogleSignInAccount?> get signInEvents => _eventsController.stream;

  /// يتهيأ مرة واحدة؛ آمن يتنادى أكتر من مرة.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    if (!isConfigured) return;
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb
          ? AppConfig.googleClientId
          : (AppConfig.googleIosClientId.isEmpty
              ? null
              : AppConfig.googleIosClientId),
      serverClientId: AppConfig.googleClientId,
    );
    GoogleSignIn.instance.authenticationEvents.listen(
      (event) {
        switch (event) {
          case GoogleSignInAuthenticationEventSignIn():
            _account = event.user;
          case GoogleSignInAuthenticationEventSignOut():
            _account = null;
        }
        _eventsController.add(_account);
      },
      onError: (Object e) {
        _eventsController.addError(e);
      },
    );
  }

  /// هل المنصة بتدعم زرار مخصص (موبايل) ولا لازم زرار جوجل نفسه (ويب)؟
  bool get supportsCustomButton {
    if (!isConfigured) return true; // نعرض زرارنا ونظهر رسالة خطأ عند الضغط
    return GoogleSignIn.instance.supportsAuthenticate();
  }

  /// تسجيل دخول من الزرار المخصص (موبايل). بيرجع الـ ID token.
  /// بيرمي GoogleSignInException لو المستخدم لغى أو حصل خطأ.
  Future<String> signInAndGetIdToken() async {
    await ensureInitialized();
    final account = await GoogleSignIn.instance.authenticate();
    _account = account;
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google sign-in finished without an ID token');
    }
    return idToken;
  }

  /// تسجيل خروج من جوجل (مش بيمسح جلسة التطبيق؛ دي شغلانة TokenStore).
  Future<void> signOut() async {
    if (!_initialized) return;
    _account = null;
    await GoogleSignIn.instance.signOut();
  }
}
