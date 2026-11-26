import 'dart:convert';

import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../auth/token_store.dart';
import 'api_exception.dart';

/// عميل HTTP بسيط بيتعامل مع غلاف الاستجابة الموحد بتاع الباك:
/// { success, data, error, traceId }
class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _http = httpClient ?? http.Client(),
        baseUrl = baseUrl ?? defaultBaseUrl;

  /// Override at run time: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1
  static const String defaultBaseUrl = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'https://hamzet-wasl-backend.onrender.com/api/v1');

  final http.Client _http;
  final String baseUrl;

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> _headers({bool auth = false}) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (auth && TokenStore.instance.accessToken != null)
          'Authorization': 'Bearer ${TokenStore.instance.accessToken}',
      };

  Future<Map<String, dynamic>> get(String path, {bool auth = false}) async {
    final res = await _http.get(_uri(path), headers: _headers(auth: auth));
    return _decode(res);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final res = await _http.post(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body, {
    bool auth = false,
  }) async {
    final res = await _http.put(
      _uri(path),
      headers: _headers(auth: auth),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  /// رفع ملف (multipart) لطلبات زي صورة الوجه / البطاقة / الصورة الشخصية.
  Future<Map<String, dynamic>> multipart(
    String method,
    String path, {
    Map<String, String> fields = const {},
    required String fileField,
    required Uint8List bytes,
    required String filename,
    String? contentType,
  }) async {
    final req = http.MultipartRequest(method, _uri(path));
    req.headers['Accept'] = 'application/json';
    final token = TokenStore.instance.accessToken;
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    req.fields.addAll(fields);
    req.files.add(http.MultipartFile.fromBytes(
      fileField,
      bytes,
      filename: filename,
      contentType: contentType == null ? null : _mediaType(contentType),
    ));
    final res = await http.Response.fromStream(await _http.send(req));
    return _decode(res);
  }

  static MediaType _mediaType(String s) => MediaType.parse(s);

  Map<String, dynamic> _decode(http.Response res) {
    // بعض الطلبات الناجحة (مثل send-code / verify) بترجع 204 من غير body.
    if (res.statusCode == 204 ||
        (res.statusCode >= 200 && res.statusCode < 300 && res.body.isEmpty)) {
      return const {'success': true};
    }
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        code: 'HTTP_${res.statusCode}',
        message: 'استجابة غير صالحة من السيرفر (HTTP ${res.statusCode}).',
        statusCode: res.statusCode,
      );
    }

    if (json['success'] == true) {
      return json;
    }

    final err = json['error'];
    if (err is Map<String, dynamic>) {
      throw ApiException(
        code: err['code'] as String? ?? 'HTTP_${res.statusCode}',
        message: err['message'] as String? ?? 'حدث خطأ غير متوقع.',
        fields: (err['fields'] as Map?)?.map(
          (k, v) => MapEntry(
            k.toString(),
            (v as List).map((e) => e.toString()).toList(),
          ),
        ),
        statusCode: res.statusCode,
      );
    }
    throw ApiException(
      code: 'HTTP_${res.statusCode}',
      message: 'حدث خطأ غير متوقع (HTTP ${res.statusCode}).',
      statusCode: res.statusCode,
    );
  }
}
