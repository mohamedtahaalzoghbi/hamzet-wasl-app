import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:graduation_project/core/api/api_client.dart';
import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/auth_api.dart';

http.Client fakeClient(
  int statusCode,
  Map<String, dynamic> body, {
  void Function(http.Request)? onRequest,
}) {
  return MockClient((request) async {
    onRequest?.call(request);
    return http.Response(jsonEncode(body), statusCode, headers: {
      'content-type': 'application/json; charset=utf-8',
    });
  });
}

void main() {
  group('ApiClient envelope handling', () {
    test('returns json when success is true', () async {
      final client = ApiClient(
        httpClient: fakeClient(200, {
          'success': true,
          'data': {'registrationTicket': 'abc'},
          'error': null,
        }),
      );
      final json = await client.post('/auth/register', {});
      expect(json['success'], isTrue);
      expect((json['data'] as Map)['registrationTicket'], 'abc');
    });

    test('throws ApiException with code/message/fields on validation error',
        () async {
      final client = ApiClient(
        httpClient: fakeClient(400, {
          'success': false,
          'data': null,
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'بيانات الطلب غير صحيحة.',
            'fields': {
              'email': ['البريد الإلكتروني مطلوب.'],
            },
          },
        }),
      );
      expect(
        () => client.post('/auth/register', {}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'VALIDATION_ERROR')
              .having((e) => e.fieldError('email'), 'fieldError',
                  'البريد الإلكتروني مطلوب.'),
        ),
      );
    });

    test('treats 204 No Content as success', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('', 204)),
      );
      final json = await client.post('/auth/email/verify', {'code': '123456'});
      expect(json['success'], isTrue);
    });

    test('throws ApiException on non-JSON response', () async {
      final client = ApiClient(
        httpClient: MockClient((request) async => http.Response('oops', 502)),
      );
      expect(
        () => client.get('/auth/session'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'HTTP_502')),
      );
    });
  });

  group('AuthApi payloads', () {
    test('register sends the backend contract body', () async {
      http.Request? seen;
      final api = AuthApi(
        client: ApiClient(
          httpClient: fakeClient(200, {
            'success': true,
            'data': {
              'requiresPhoneVerification': true,
              'registrationTicket': 'ticket-1',
              'expiresAt': '2026-11-25T20:23:45Z',
              'phone': '+201000000041',
            },
            'error': null,
          }, onRequest: (r) => seen = r),
        ),
      );

      final pending = await api.register(
        role: 'volunteer',
        name: 'Test User',
        email: 'test@example.com',
        phone: '01000000041',
        password: 'Passw0rd!234',
        confirmPassword: 'Passw0rd!234',
      );

      expect(pending.registrationTicket, 'ticket-1');
      expect(seen, isNotNull);
      expect(seen!.url.path, endsWith('/api/v1/auth/register'));
      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body['role'], 'volunteer');
      expect(body['email'], 'test@example.com');
      expect(body['confirmPassword'], 'Passw0rd!234');
      expect(body['termsAccepted'], isTrue);
    });

    test('completeRegistration sends ticket + code', () async {
      http.Request? seen;
      final api = AuthApi(
        client: ApiClient(
          httpClient: fakeClient(201, {
            'success': true,
            'data': {
              'userId': 'u1',
              'role': 'volunteer',
              'accountStatus': 'active',
              'accessToken': 'a',
              'refreshToken': 'r',
            },
            'error': null,
          }, onRequest: (r) => seen = r),
        ),
      );

      final auth = await api.completeRegistration(
        registrationTicket: 'ticket-1',
        code: '123456',
      );

      final body = jsonDecode(seen!.body) as Map<String, dynamic>;
      expect(body, {'registrationTicket': 'ticket-1', 'code': '123456'});
      expect(auth.accessToken, 'a');
      expect(auth.refreshToken, 'r');
    });
  });
}
