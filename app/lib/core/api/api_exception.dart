/// خطأ راجع من الـ API (success = false أو HTTP error).
class ApiException implements Exception {
  ApiException({
    required this.code,
    required this.message,
    this.fields,
    this.statusCode,
  });

  /// كود الخطأ من السيرفر (مثال: VALIDATION_ERROR, INVALID_CREDENTIALS).
  final String code;

  /// رسالة الخطأ الجاهزة للعرض (بتيجي عربي من السيرفر).
  final String message;

  /// أخطاء الحقول: اسم الحقل -> قائمة الرسائل.
  final Map<String, List<String>>? fields;

  /// HTTP status code (لو موجود).
  final int? statusCode;

  /// أول رسالة خطأ على حقل معين (لو موجودة).
  String? fieldError(String field) {
    final list = fields?[field];
    return (list != null && list.isNotEmpty) ? list.first : null;
  }

  @override
  String toString() => 'ApiException($code): $message';
}

/// رسالة جاهزة للعرض لأي خطأ (رسالة السيرفر لو ApiException).
String apiErrorMessage(Object e) =>
    e is ApiException ? e.message : 'مشكلة في الاتصال بالسيرفر. حاول تاني.';
