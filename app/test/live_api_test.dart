// Live integration test against the deployed backend.
//
// Runs ONLY when enabled explicitly:
//   flutter test test/live_api_test.dart --dart-define=RUN_LIVE_API=1
//
// Uses the fixed demo OTP (123456) that is enabled on the test deployment
// and creates throwaway @example.com accounts only.

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/auth_api.dart';
import 'package:graduation_project/core/auth/token_store.dart';

// flutter test لا يمرر --dart-define بشكل موثوق للتستات، فنستخدم متغير بيئة:
//   RUN_LIVE_API=1 flutter test test/live_api_test.dart
final bool _runLive = Platform.environment['RUN_LIVE_API'] == '1';

void main() {
  if (!_runLive) {
    test('live API tests disabled (pass --dart-define=RUN_LIVE_API=1)', () {
      expect(_runLive, isFalse);
    });
    return;
  }

  final api = AuthApi.instance;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'live.test.$stamp@example.com';
  final phone = '010${(stamp % 100000000).toString().padLeft(8, '0')}';
  const password = 'Passw0rd!234';
  const demoOtp = '123456';

  group('live backend: full registration + auth flow', () {
    setUpAll(() {
      // TokenStore بيستخدم shared_preferences؛ في التست نستخدم نسخة وهمية.
      SharedPreferences.setMockInitialValues({});
    });

    test('validation errors come back with field details', () async {
      try {
        await api.register(
          role: 'volunteer',
          name: '',
          email: 'not-an-email',
          phone: '123',
          password: 'short',
          confirmPassword: 'short',
          termsAccepted: false,
        );
        fail('expected ApiException');
      } on ApiException catch (e) {
        expect(e.code, 'VALIDATION_ERROR');
        expect(e.fields, isNotNull);
        expect(e.fields!.keys, containsAll(['email', 'phone', 'password']));
      }
    });

    test('register -> complete (demo OTP) -> session -> login -> refresh',
        () async {
      // Step 1: register returns a ticket, no account yet.
      final pending = await api.register(
        role: 'volunteer',
        name: 'Live Test',
        email: email,
        phone: phone,
        password: password,
        confirmPassword: password,
      );
      expect(pending.registrationTicket, isNotEmpty);
      expect(pending.requiresPhoneVerification, isTrue);

      // Wrong OTP must be rejected.
      try {
        await api.completeRegistration(
          registrationTicket: pending.registrationTicket,
          code: '000000',
        );
        fail('expected ApiException for wrong OTP');
      } on ApiException catch (e) {
        expect(e.code, isNot('REGISTRATION_EXPIRED'));
      }

      // Step 2: correct demo OTP creates the account and returns tokens.
      final auth = await api.completeRegistration(
        registrationTicket: pending.registrationTicket,
        code: demoOtp,
      );
      expect(auth.accessToken, isNotNull);
      expect(auth.refreshToken, isNotNull);
      expect(auth.role, 'volunteer');
      expect(auth.phoneVerified, isTrue);

      // Ticket cannot be reused.
      expect(
        () => api.completeRegistration(
          registrationTicket: pending.registrationTicket,
          code: demoOtp,
        ),
        throwsA(isA<ApiException>()),
      );

      // Session works with the access token.
      await TokenStore.instance.save(auth);
      expect(TokenStore.instance.accessToken, auth.accessToken);
      final session = await api.session();
      expect(session.email, email);
      expect(session.userId, auth.userId);

      // Duplicate registration is rejected.
      expect(
        () => api.register(
          role: 'volunteer',
          name: 'Live Test',
          email: email,
          phone: phone,
          password: password,
          confirmPassword: password,
        ),
        throwsA(isA<ApiException>()),
      );

      // Login with email and with phone both work.
      final byEmail = await api.login(emailOrPhone: email, password: password);
      expect(byEmail.userId, auth.userId);
      final byPhone = await api.login(emailOrPhone: phone, password: password);
      expect(byPhone.userId, auth.userId);

      // Wrong password is rejected.
      expect(
        () => api.login(emailOrPhone: email, password: 'wrong-password'),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')),
      );

      // Refresh rotates tokens.
      final refreshed = await api.refresh(byEmail.refreshToken!);
      expect(refreshed.accessToken, isNotNull);

      // Resend on a consumed ticket fails.
      expect(
        () => api.resendRegistrationCode(pending.registrationTicket),
        throwsA(isA<ApiException>()),
      );
    });
  });
}
