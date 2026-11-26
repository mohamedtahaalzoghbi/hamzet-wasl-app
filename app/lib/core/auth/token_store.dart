import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_models.dart';

/// تخزين التوكنات محليًا عشان الجلسة تفضل شغالة بعد قفل التطبيق.
class TokenStore {
  TokenStore._();

  static final TokenStore instance = TokenStore._();

  static const _kAccessToken = 'hw_access_token';
  static const _kAccessExpiry = 'hw_access_token_expiry';
  static const _kRefreshToken = 'hw_refresh_token';
  static const _kRefreshExpiry = 'hw_refresh_token_expiry';

  String? accessToken;
  String? refreshToken;
  DateTime? accessTokenExpiresAt;
  DateTime? refreshTokenExpiresAt;

  bool get hasSession => accessToken != null;

  /// التوكن خلاص قرب يخلص أو خلص فعلًا.
  bool get accessTokenExpired {
    final expiry = accessTokenExpiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(
      expiry.subtract(const Duration(minutes: 1)),
    );
  }

  /// نقرأ التوكنات المحفوظة (يتنادى مرة واحدة عند تشغيل التطبيق).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kAccessToken);
    refreshToken = prefs.getString(_kRefreshToken);
    accessTokenExpiresAt = _parse(prefs.getString(_kAccessExpiry));
    refreshTokenExpiresAt = _parse(prefs.getString(_kRefreshExpiry));
  }

  Future<void> save(AuthResult auth) async {
    accessToken = auth.accessToken;
    refreshToken = auth.refreshToken;
    accessTokenExpiresAt = auth.accessTokenExpiresAt;
    refreshTokenExpiresAt = auth.refreshTokenExpiresAt;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccessToken, auth.accessToken ?? '');
    await prefs.setString(
      _kAccessExpiry,
      auth.accessTokenExpiresAt?.toIso8601String() ?? '',
    );
    await prefs.setString(_kRefreshToken, auth.refreshToken ?? '');
    await prefs.setString(
      _kRefreshExpiry,
      auth.refreshTokenExpiresAt?.toIso8601String() ?? '',
    );
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    accessTokenExpiresAt = null;
    refreshTokenExpiresAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccessToken);
    await prefs.remove(_kAccessExpiry);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kRefreshExpiry);
  }

  static DateTime? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
