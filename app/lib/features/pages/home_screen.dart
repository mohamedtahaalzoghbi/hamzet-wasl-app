import 'package:flutter/material.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/auth_api.dart';
import '../../core/api/auth_models.dart';
import '../../core/api/profile_api.dart';
import '../../core/auth/token_store.dart';
import '../../core/usersection.dart';
import '../../widgets/Colors.dart';
import '../../widgets/volunteerwidgets.dart';
import 'AccountTypeScreen.dart';
import 'organization_setup_screen.dart';
import 'volunteer/identify_info.dart';
import 'volunteer/interview_screen.dart';

/// الشاشة الرئيسية بعد الدخول: بتقرا الجلسة من الباك وتعرض حالة الحساب
/// وبتكمل الخطوة الناقصة (التحقق للمتطوع / بيانات الجهة للشركة والجمعية).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SessionInfo? _session;
  VerificationStatus? _ver;
  OrgState? _org;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await AuthApi.instance.session();
      UserSession.email = s.email;
      UserSession.phone = s.phone;
      UserSession.accountKind = _kind(s.role);
      VerificationStatus? v;
      OrgState? o;
      if (s.role == 'volunteer') v = await ProfileApi.instance.verification();
      if (s.role == 'company' || s.role == 'association') {
        o = await ProfileApi.instance.organization();
        bool sub = false;
        try { sub = await ProfileApi.instance.orgSubmitted(); } catch (_) {}
        o = OrgState(name: o.name, approvalStatus: o.approvalStatus, missingDocuments: o.missingDocuments,
            canSubmit: o.canSubmit, hasLogo: o.hasLogo, completion: o.completion, submitted: sub);
      }
      if (!mounted) return;
      setState(() {
        _session = s;
        _ver = v;
        _org = o;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) return _logout(silent: true);
      if (mounted) setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = apiErrorMessage(e);
        _loading = false;
      });
    }
  }

  static AccountKind? _kind(String role) {
    switch (role) {
      case 'volunteer':
        return AccountKind.volunteer;
      case 'company':
        return AccountKind.company;
      case 'association':
        return AccountKind.organization;
      case 'disabled_user':
        return AccountKind.interested;
    }
    return null;
  }

  Future<void> _logout({bool silent = false}) async {
    if (!silent) {
      try {
        await AuthApi.instance.logout();
      } catch (_) {}
    }
    await TokenStore.instance.clear();
    UserSession.reset();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const AccountTypeScreen()), (_) => false);
  }

  String get _roleLabel {
    switch (_session?.role) {
      case 'volunteer':
        return 'متطوع';
      case 'company':
        return 'شركة';
      case 'association':
        return 'جمعية / منظمة';
      case 'disabled_user':
        return 'فرد مهتم';
      case 'admin':
        return 'مدير';
    }
    return '';
  }

  String _verLabel(String s) {
    switch (s) {
      case 'unverified':
        return 'لسه مكمّلتش خطوات التحقق';
      case 'pending':
        return 'طلبك قيد المراجعة';
      case 'interview_scheduled':
        return 'تم حجز مقابلة التحقق';
      case 'approved':
        return 'تم توثيق حسابك';
      case 'rejected':
        return 'تم رفض طلب التحقق';
    }
    return s;
  }

  String _orgLabel(String s, [bool submitted = false]) {
    switch (s) {
      case 'approved':
        return 'تم اعتماد الجهة';
      case 'rejected':
        return 'تم رفض الطلب';
    }
    return submitted ? 'طلبك قيد المراجعة' : 'لسه مكمّلتش بيانات الجهة والمستندات';
  }

  void _continue() {
    final role = _session?.role;
    Widget? next;
    if (role == 'volunteer') {
      final v = _ver;
      next = (v != null && v.canBookInterview) ? const InterviewScreen() : const IdentityIntroScreen();
    } else if (role == 'company' || role == 'association') {
      next = const OrganizationSetupScreen();
    }
    if (next != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => next!)).then((_) => _load());
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null || s == null) {
      body = Column(children: [
        const SizedBox(height: 60),
        Text(_error ?? 'مشكلة في الاتصال', textAlign: TextAlign.center, style: vText(size: 14)),
        const SizedBox(height: 16),
        VButton(title: 'إعادة المحاولة', onPressed: _load),
        const SizedBox(height: 10),
        VButton(title: 'تسجيل الخروج', onPressed: _logout),
      ]);
    } else {
      final status = _ver != null
          ? _verLabel(_ver!.status)
          : (_org != null ? _orgLabel(_org!.approvalStatus, _org!.submitted) : null);
      final canContinue = (_ver != null && _ver!.status != 'approved' && _ver!.status != 'pending') ||
          (_org != null && _org!.approvalStatus != 'approved' && !(_org!.submitted && _org!.approvalStatus == 'pending'));
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Text('أهلاً ${s.displayName ?? ''}', textAlign: TextAlign.center, style: vText(size: 22, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_roleLabel, textAlign: TextAlign.center, style: vText(size: 14, color: AppColors.TextSecondaryLight)),
          const SizedBox(height: 24),
          if (status != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(status, textAlign: TextAlign.center, style: vText(size: 14, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 8),
          Text(
            s.emailVerified ? 'الإيميل متأكد' : 'الإيميل لسه مش متأكد',
            textAlign: TextAlign.center,
            style: vText(size: 12, color: AppColors.TextSecondaryLight),
          ),
          const SizedBox(height: 24),
          if (canContinue) ...[
            VButton(title: 'كمّل الخطوات', onPressed: _continue),
            const SizedBox(height: 10),
          ],
          VButton(title: 'تسجيل الخروج', color: AppColors.terracotta, onPressed: _logout),
        ],
      );
    }
    return VolunteerScaffold(body: body);
  }
}
