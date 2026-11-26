/// إعدادات عامة للتطبيق بتتحدد وقت البناء.
class AppConfig {
  AppConfig._();

  /// الـ Web OAuth client ID بتاع مشروع جوجل على Google Cloud.
  /// هو نفسه الـ audience اللي الباك بيتحقق منها (Google:ClientId).
  /// يتبعت وقت البناء:
  /// flutter build web --dart-define=GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '589277982601-73jknuq229evbfuc4fa597asdvsjrtqg.apps.googleusercontent.com');

  /// الـ iOS OAuth client ID (لمنصات أبل بس؛ أندرويد مش محتاجه).
  static const String googleIosClientId =
      String.fromEnvironment('GOOGLE_IOS_CLIENT_ID', defaultValue: '');

  static bool get googleSignInConfigured => googleClientId.isNotEmpty;
}
