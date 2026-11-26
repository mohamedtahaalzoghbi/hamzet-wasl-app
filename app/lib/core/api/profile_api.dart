import 'dart:typed_data';

import 'api_client.dart';

class MetaItem {
  const MetaItem(this.id, this.name);
  final int id;
  final String name;
}

class GovernorateMeta {
  const GovernorateMeta(this.key, this.nameAr, this.areas);
  final String key;
  final String nameAr;
  final List<String> areas; // أسماء المناطق بالعربي
}

class VerificationStatus {
  const VerificationStatus({
    required this.status,
    required this.currentStep,
    required this.canBookInterview,
    required this.completedSteps,
  });
  final String status;
  final String? currentStep;
  final bool canBookInterview;
  final Set<String> completedSteps;
}

class InterviewSlot {
  const InterviewSlot(this.id, this.startsAt);
  final String id;
  final DateTime? startsAt;
}

/// طلبات الملف الشخصي / المتطوع / التحقق / الإتاحة / المقابلة.
/// كل الأسماء والقيم متطابقة مع swagger السيرفر المرفوع.
class ProfileApi {
  ProfileApi({ApiClient? client}) : _c = client ?? ApiClient();
  static final ProfileApi instance = ProfileApi();
  final ApiClient _c;

  // ---------- قوائم ثابتة (public) ----------
  Future<List<MetaItem>> _metaItems(String path) async {
    final json = await _c.get(path);
    return ((json['data'] as List?) ?? [])
        .map((e) => MetaItem(
              (e['id'] as num).toInt(),
              (e['nameAr'] ?? e['name'] ?? '').toString(),
            ))
        .toList();
  }

  Future<List<MetaItem>> skills() => _metaItems('/meta/skills');
  Future<List<MetaItem>> interests() => _metaItems('/meta/interests');

  Future<List<GovernorateMeta>> governorates() async {
    final json = await _c.get('/meta/governorates');
    return ((json['data'] as List?) ?? [])
        .map((e) => GovernorateMeta(
              e['key'].toString(),
              e['nameAr'].toString(),
              ((e['areas'] as List?) ?? [])
                  .map((a) => a['nameAr'].toString())
                  .toList(),
            ))
        .toList();
  }

  // ---------- الملف الشخصي ----------
  Future<void> updateProfile({String? displayName, String? bio, String visibility = 'public'}) async {
    // الباك بيطلب displayName في كل تعديل، فلو مش متبعت بنقراه من الملف الحالي.
    if (displayName == null) {
      final cur = await _c.get('/me/profile', auth: true);
      displayName = ((cur['data'] as Map?)?['displayName'] ?? '').toString();
    }
    await _c.put('/me/profile', {
      'displayName': displayName,
      if (bio != null) 'bio': bio,
      'visibility': visibility,
    }, auth: true);
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename, String mime) async {
    await _c.multipart('PUT', '/me/profile/avatar',
        fileField: 'file', bytes: bytes, filename: filename, contentType: mime, );
  }

  Future<void> setInterests(List<int> ids) async {
    await _c.put('/me/interests', {'interestIds': ids}, auth: true);
  }

  Future<void> setSkills(List<int> ids) async {
    await _c.put('/me/skills', {'skillIds': ids}, auth: true);
  }

  /// بيشتغل لحساب "ذوي همم" فقط (السيرفر بيرجع 403 للأدوار التانية).
  Future<void> setAccessibility(String needType) async {
    await _c.put('/me/accessibility', {
      'needType': needType,
      'needTypes': [needType],
      'theme': 'system',
      'fontScale': 1,
      'reducedMotion': false,
      'interactionMode': 'touch',
      'notificationMode': 'in_app',
      'manualOverrides': <String, dynamic>{},
    }, auth: true);
  }

  // ---------- المتطوع ----------
  Future<void> saveVolunteerProfile({
    required String introduction,
    required String helpMode, // online_only | online_and_field
    required String skillLevel, // beginner | intermediate | advanced
    required int weeklyHours,
    String? experienceNotes,
    List<int> skillIds = const [],
  }) async {
    await _c.put('/me/volunteer-profile', {
      'introduction': introduction,
      'helpMode': helpMode,
      'skillLevel': skillLevel,
      'weeklyHours': weeklyHours,
      if (experienceNotes != null) 'experienceNotes': experienceNotes,
      'skillIds': skillIds,
    }, auth: true);
  }

  Future<void> saveVolunteerLocation({
    required String governorate,
    String? serviceArea,
    required int radiusKm,
    double? latitude,
    double? longitude,
  }) async {
    await _c.put('/me/volunteer-location', {
      'governorate': governorate,
      if (serviceArea != null) 'serviceArea': serviceArea,
      'serviceRadiusKm': radiusKm,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    }, auth: true);
  }

  // ---------- التحقق ----------
  Future<VerificationStatus> verification() async {
    final json = await _c.get('/me/verification', auth: true);
    final d = (json['data'] as Map).cast<String, dynamic>();
    final done = <String>{};
    for (final s in (d['steps'] as List? ?? [])) {
      if (s['completed'] == true) done.add(s['key'].toString());
    }
    return VerificationStatus(
      status: (d['status'] ?? '').toString(),
      currentStep: d['currentStep']?.toString(),
      canBookInterview: d['canBookInterview'] == true,
      completedSteps: done,
    );
  }

  /// evidenceType: national_id_front | national_id_back | face_photo
  /// يتطلب إيميل وموبايل متأكدين قبلها.
  Future<void> uploadEvidence(
      String evidenceType, Uint8List bytes, String filename, String mime) async {
    await _c.multipart('POST', '/me/verification/evidence',
        fields: {'evidenceType': evidenceType},
        fileField: 'file',
        bytes: bytes,
        filename: filename,
        contentType: mime);
  }

  Future<void> saveSocialLinks(Map<String, String> links) async {
    await _c.put('/me/verification/social-links', {
      'links': links.entries
          .where((e) => e.value.trim().isNotEmpty)
          .map((e) => {'platform': e.key, 'url': e.value.trim()})
          .toList(),
    }, auth: true);
  }

  Future<List<InterviewSlot>> interviewSlots() async {
    final json = await _c.get('/interview-slots', auth: true);
    return ((json['data'] as List?) ?? []).map((e) {
      final m = (e as Map).cast<String, dynamic>();
      final t = (m['startsAt'] ?? m['startAt'] ?? m['start'] ?? m['scheduledAt'])?.toString();
      return InterviewSlot((m['interviewSlotId'] ?? m['id']).toString(), t == null ? null : DateTime.tryParse(t));
    }).toList();
  }

  Future<void> bookInterview(String slotId) async {
    await _c.post('/me/verification/interview', {'interviewSlotId': slotId}, auth: true);
  }

  // ---------- الجهة (شركة / جمعية) ----------
  Future<List<KeyedMeta>> _keyed(String path) async {
    final json = await _c.get(path);
    return ((json['data'] as List?) ?? [])
        .map((e) => KeyedMeta(e['key'].toString(), e['nameAr'].toString()))
        .toList();
  }

  Future<List<KeyedMeta>> businessFields() => _keyed('/meta/business-fields');
  Future<List<KeyedMeta>> employeeRanges() => _keyed('/meta/employee-ranges');

  Future<OrgState> organization() async {
    final json = await _c.get('/me/organization', auth: true);
    final d = (json['data'] as Map).cast<String, dynamic>();
    return OrgState(
      name: (d['name'] ?? '').toString(),
      approvalStatus: (d['approvalStatus'] ?? '').toString(),
      missingDocuments:
          ((d['missingDocuments'] as List?) ?? []).map((e) => e.toString()).toList(),
      canSubmit: d['canSubmit'] == true,
      hasLogo: (d['logoUrl'] ?? '').toString().isNotEmpty,
      completion: (d['profileCompletionPercent'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> saveOrganization({
    required String name,
    String? field,
    String? description,
    String? governorate,
    String? city,
    String? website,
    String? employeeCountRange,
    String? contactInformation,
  }) async {
    await _c.put('/me/organization', {
      'name': name,
      if (field != null) 'field': field,
      if (description != null) 'description': description,
      if (governorate != null) 'governorate': governorate,
      if (city != null) 'city': city,
      if (website != null && website.isNotEmpty) 'website': website,
      if (employeeCountRange != null) 'employeeCountRange': employeeCountRange,
      if (contactInformation != null) 'contactInformation': contactInformation,
    }, auth: true);
  }

  Future<void> uploadOrgLogo(Uint8List b, String name, String mime) async {
    await _c.multipart('PUT', '/me/organization/logo',
        fileField: 'file', bytes: b, filename: name, contentType: mime);
  }

  /// documentType: commercial_register | tax_card | address_proof | license
  Future<void> uploadOrgDocument(
      String type, Uint8List b, String name, String mime) async {
    await _c.multipart('PUT', '/me/organization/documents/$type',
        fileField: 'file', bytes: b, filename: name, contentType: mime);
  }

  Future<void> submitOrganization() async {
    await _c.post('/me/organization/submit', {}, auth: true);
  }

  Future<bool> orgSubmitted() async {
    final json = await _c.get('/me/organization/review-status', auth: true);
    return ((json['data'] as Map?)?['reviewId']) != null;
  }

  Future<String?> orgReviewNotes() async {
    final json = await _c.get('/me/organization/review-status', auth: true);
    return ((json['data'] as Map?)?['decisionNotes'])?.toString();
  }
}

class KeyedMeta {
  const KeyedMeta(this.key, this.nameAr);
  final String key;
  final String nameAr;
}

class OrgState {
  const OrgState({
    required this.name,
    required this.approvalStatus,
    required this.missingDocuments,
    required this.canSubmit,
    required this.hasLogo,
    required this.completion,
    this.submitted = false,
  });
  final bool submitted;
  final String name;
  final String approvalStatus;
  final List<String> missingDocuments;
  final bool canSubmit;
  final bool hasLogo;
  final int completion;
}
