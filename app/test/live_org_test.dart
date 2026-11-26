// RUN_LIVE_API=1 flutter test test/live_org_test.dart  (throwaway @example.com company)
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:graduation_project/core/api/auth_api.dart';
import 'package:graduation_project/core/api/profile_api.dart';
import 'package:graduation_project/core/auth/token_store.dart';

final bool _run = Platform.environment['RUN_LIVE_API'] == '1';
final Uint8List _png = Uint8List.fromList(const [
  0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00, 0x00, 0x00, 0x0d,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xde, 0x00, 0x00, 0x00,
  0x0c, 0x49, 0x44, 0x41, 0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
  0x00, 0x03, 0x01, 0x01, 0x00, 0x18, 0xdd, 0x8d, 0xb0, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4e, 0x44, 0xae, 0x42, 0x60, 0x82,
]);

void main() {
  if (!_run) {
    test('live org tests disabled', () => expect(_run, isFalse));
    return;
  }
  final stamp = DateTime.now().millisecondsSinceEpoch;
  test('company: info, logo, documents, submit, home data', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await AuthApi.instance.register(
        role: 'company', name: 'شركة تجريبية', organizationName: 'شركة تجريبية',
        email: 'live.org.$stamp@example.com',
        phone: '012${(stamp % 100000000).toString().padLeft(8, '0')}',
        password: 'Passw0rd!234', confirmPassword: 'Passw0rd!234');
    final r = await AuthApi.instance.completeRegistration(
        registrationTicket: p.registrationTicket, code: '123456');
    await TokenStore.instance.save(r);
    final s = await AuthApi.instance.session();
    expect(s.role, 'company');

    final api = ProfileApi.instance;
    final fields = await api.businessFields();
    final ranges = await api.employeeRanges();
    final govs = await api.governorates();
    final gv = govs.firstWhere((g) => g.areas.isNotEmpty);
    var o = await api.organization();
    expect(o.canSubmit, isFalse);
    await api.saveOrganization(
        name: 'شركة تجريبية', field: fields.first.key, description: 'وصف',
        governorate: gv.nameAr, city: gv.areas.first, website: 'https://example.com',
        employeeCountRange: ranges.first.key, contactInformation: 'info@example.com');
    await api.uploadOrgLogo(_png, 'logo.png', 'image/png');
    for (final d in ['commercial_register', 'tax_card', 'address_proof']) {
      await api.uploadOrgDocument(d, _png, '$d.png', 'image/png');
    }
    o = await api.organization();
    expect(o.canSubmit, isTrue, reason: 'missing: ${o.missingDocuments}');
    await api.submitOrganization();
    await api.orgReviewNotes();
  });
}
