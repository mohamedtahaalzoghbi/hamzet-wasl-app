// Live test of the volunteer onboarding endpoints used by the wired screens.
// Run: RUN_LIVE_API=1 flutter test test/live_profile_test.dart
// Creates a throwaway @example.com account; fixed demo OTP 123456.
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/auth_api.dart';
import 'package:graduation_project/core/api/profile_api.dart';
import 'package:graduation_project/core/auth/token_store.dart';

final bool _runLive = Platform.environment['RUN_LIVE_API'] == '1';

// 1x1 PNG
final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
  0x0c, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb0, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

void main() {
  if (!_runLive) {
    test('live profile tests disabled', () => expect(_runLive, isFalse));
    return;
  }
  final auth = AuthApi.instance;
  final api = ProfileApi.instance;
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final email = 'live.prof.$stamp@example.com';
  final phone = '011${(stamp % 100000000).toString().padLeft(8, '0')}';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final p = await auth.register(
        role: 'volunteer', name: 'Live Prof', email: email, phone: phone,
        password: 'Passw0rd!234', confirmPassword: 'Passw0rd!234');
    final r = await auth.completeRegistration(
        registrationTicket: p.registrationTicket, code: '123456');
    await TokenStore.instance.save(r);
  });

  test('meta lists load', () async {
    expect((await api.skills()).length, greaterThan(3));
    expect((await api.interests()).length, greaterThan(3));
    final g = await api.governorates();
    expect(g.length, 27);
    expect(g.firstWhere((x) => x.nameAr == 'القاهرة').areas, isNotEmpty);
  });

  test('profile, interests, skills, volunteer profile + location', () async {
    await api.updateProfile(bio: 'نبذة تجريبية');
    await api.setInterests([1, 3]);
    await api.setSkills([1, 3]);
    await api.saveVolunteerProfile(
        introduction: 'نبذة', helpMode: 'online_and_field',
        skillLevel: 'intermediate', weeklyHours: 6,
        experienceNotes: 'x', skillIds: [1, 3]);
    await api.saveVolunteerLocation(
        governorate: 'القاهرة', serviceArea: 'المعادي', radiusKm: 20);
    expect(
        () => api.saveVolunteerLocation(
            governorate: 'القاهرة', serviceArea: 'منطقة غلط', radiusKm: 20),
        throwsA(isA<ApiException>()));
    expect(
        () => api.saveVolunteerLocation(
            governorate: 'القاهرة', radiusKm: 150),
        throwsA(isA<ApiException>()));
  });

  test('accessibility is rejected for volunteer accounts', () async {
    expect(() => api.setAccessibility('motor'), throwsA(isA<ApiException>()));
  });

  test('evidence upload needs verified email, then works', () async {
    expect(() => api.uploadEvidence('face_photo', _png, 'a.png', 'image/png'),
        throwsA(isA<ApiException>()));
    await auth.sendEmailCode();
    await auth.verifyEmailCode('123456');
    await api.uploadEvidence('face_photo', _png, 'a.png', 'image/png');
    await api.uploadEvidence('national_id_front', _png, 'f.png', 'image/png');
    await api.uploadEvidence('national_id_back', _png, 'b.png', 'image/png');
    await api.uploadAvatar(_png, 'av.png', 'image/png');
  });

  test('social links, verification status, interview slots', () async {
    await api.saveSocialLinks({'facebook': 'https://facebook.com/live.test'});
    final v = await api.verification();
    expect(v.completedSteps,
        containsAll(['email', 'phone', 'face_photo', 'national_id_front', 'national_id_back', 'social_links']));
    final slots = await api.interviewSlots();
    // ignore: avoid_print
    print('interview slots available: ${slots.length}');
    if (slots.isNotEmpty) {
      await api.bookInterview(slots.first.id);
    }
  });
}
