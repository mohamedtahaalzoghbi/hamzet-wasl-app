import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/profile_api.dart';
import '../../core/api/upload_util.dart';
import '../../core/usersection.dart';
import '../../widgets/Colors.dart';
import '../../widgets/choice_sheets.dart';
import '../../widgets/volunteerwidgets.dart';
import 'home_screen.dart';

/// إعداد حساب الشركة / الجمعية: بيانات الجهة + اللوجو + المستندات + الإرسال للمراجعة.
/// كل خطوة مربوطة بـ /me/organization.
class OrganizationSetupScreen extends StatefulWidget {
  const OrganizationSetupScreen({super.key});

  @override
  State<OrganizationSetupScreen> createState() => _OrganizationSetupScreenState();
}

class _OrganizationSetupScreenState extends State<OrganizationSetupScreen> {
  static const _docs = {
    'commercial_register': 'السجل التجاري',
    'tax_card': 'البطاقة الضريبية',
    'address_proof': 'إثبات العنوان',
  };

  final _name = TextEditingController();
  final _field = TextEditingController();
  final _desc = TextEditingController();
  final _gov = TextEditingController();
  final _city = TextEditingController();
  final _site = TextEditingController();
  final _range = TextEditingController();
  final _contact = TextEditingController();

  String? _fieldKey;
  String? _rangeKey;
  OrgState? _org;
  final Set<String> _uploaded = {};
  bool _logo = false;
  bool _busy = false;
  bool _loading = true;
  String? _error;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final o = await ProfileApi.instance.organization();
      if (!mounted) return;
      setState(() {
        _org = o;
        _name.text = o.name;
        _logo = o.hasLogo;
        _uploaded.addAll(_docs.keys.where((k) => !o.missingDocuments.contains(k)));
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = apiErrorMessage(e);
      });
    }
  }

  Future<void> _pickKeyed(TextEditingController c, Future<List<KeyedMeta>> Function() load,
      String title, void Function(String key) onKey) async {
    try {
      final items = await load();
      if (!mounted) return;
      final r = await showVSheet<String>(context,
          builder: (_) => SingleChoiceSheet(title: title, options: items.map((e) => e.nameAr).toList()));
      if (r == null) return;
      final it = items.firstWhere((e) => e.nameAr == r);
      setState(() {
        c.text = RegExp(r'[0-9]').hasMatch(it.nameAr) ? '\u2066${it.nameAr}\u2069' : it.nameAr;
        onKey(it.key);
      });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    }
  }

  Future<void> _pickGov() async {
    try {
      final g = await ProfileApi.instance.governorates();
      if (!mounted) return;
      final r = await showVSheet<String>(context,
          builder: (_) => SingleChoiceSheet(title: 'المحافظة', options: g.map((e) => e.nameAr).toList()));
      if (r != null) setState(() { if (_gov.text != r) _city.clear(); _gov.text = r; });
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    }
  }

  Future<void> _pickCity() async {
    if (_gov.text.isEmpty) {
      setState(() => _error = 'اختر المحافظة الأول');
      return;
    }
    try {
      final g = await ProfileApi.instance.governorates();
      final areas = g.firstWhere((e) => e.nameAr == _gov.text).areas;
      if (!mounted) return;
      final r = await showVSheet<String>(context,
          builder: (_) => SingleChoiceSheet(title: 'المنطقة', options: areas));
      if (r != null) setState(() => _city.text = r);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    }
  }

  Future<XFile?> _pickFile() => ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);

  Future<void> _saveInfo() async {
    setState(() {
      _showErrors = true;
      _error = null;
    });
    if (_name.text.trim().length < 2 || _fieldKey == null || _desc.text.trim().isEmpty ||
        _gov.text.isEmpty || _city.text.trim().isEmpty || _rangeKey == null || _contact.text.trim().isEmpty) {
      return;
    }
    await _run(() => ProfileApi.instance.saveOrganization(
          name: _name.text.trim(),
          field: _fieldKey,
          description: _desc.text.trim(),
          governorate: _gov.text,
          city: _city.text.trim(),
          website: _site.text.trim(),
          employeeCountRange: _rangeKey,
          contactInformation: _contact.text.trim(),
        ));
    _snack('تم حفظ بيانات الجهة');
  }

  Future<void> _upload(Future<void> Function(PickedBytes) send, void Function() ok) async {
    final f = await _pickFile();
    if (f == null) return;
    final p = await readPicked(f);
    final done = await _run(() => send(p));
    if (done) setState(ok);
  }

  Future<bool> _run(Future<void> Function() job) async {
    if (_busy) return false;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await job();
      final o = await ProfileApi.instance.organization();
      if (mounted) setState(() => _org = o);
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final ok = await _run(() => ProfileApi.instance.submitOrganization());
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  void _snack(String m) {
    if (!mounted || _error != null) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(m, style: vText(size: 13, color: Colors.white))));
  }

  Widget _uploadRow(String label, bool done, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: VButton(
          title: done ? '$label ✓ (تغيير)' : 'رفع $label',
          icon: done ? Icons.check_circle_outline : Icons.upload_file,
          color: done ? AppColors.primary_button : AppColors.terracotta,
          onPressed: _busy ? null : onTap,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const VolunteerScaffold(title: 'بيانات الجهة', body: Center(child: CircularProgressIndicator()));
    }
    final isCompany = UserSession.accountKind == AccountKind.company;
    final o = _org;
    return VolunteerScaffold(
      title: isCompany ? 'معلومات الشركة' : 'معلومات الجمعية',
      bottom: VButton(
        title: 'إرسال للمراجعة',
        onPressed: (_busy || o == null || !o.canSubmit) ? null : _submit,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          VField(label: 'الاسم', hint: 'اسم الجهة', controller: _name,
              error: _showErrors && _name.text.trim().length < 2, errorText: 'اكتب اسم الجهة'),
          const SizedBox(height: 12),
          VField(label: 'مجال العمل', hint: 'اختر المجال', controller: _field, readOnly: true,
              onTap: () => _pickKeyed(_field, ProfileApi.instance.businessFields, 'مجال العمل', (k) => _fieldKey = k),
              error: _showErrors && _fieldKey == null, errorText: 'اختر المجال'),
          const SizedBox(height: 12),
          VField(label: 'نبذة عن الجهة', hint: 'اكتب نبذة', controller: _desc, maxLines: 3,
              error: _showErrors && _desc.text.trim().isEmpty, errorText: 'اكتب نبذة'),
          const SizedBox(height: 12),
          VField(label: 'المحافظة', hint: 'اختر المحافظة', controller: _gov, readOnly: true, onTap: _pickGov,
              error: _showErrors && _gov.text.isEmpty, errorText: 'اختر المحافظة'),
          const SizedBox(height: 12),
          VField(label: 'المنطقة', hint: 'اختر المنطقة', controller: _city, readOnly: true, onTap: _pickCity,
              error: _showErrors && _city.text.trim().isEmpty, errorText: 'اختر المنطقة'),
          const SizedBox(height: 12),
          VField(label: 'الموقع الإلكتروني (اختياري)', hint: '\u2066https://\u2069', controller: _site, ltr: true),
          const SizedBox(height: 12),
          VField(label: 'عدد الموظفين', hint: 'اختر', controller: _range, readOnly: true,
              onTap: () => _pickKeyed(_range, ProfileApi.instance.employeeRanges, 'عدد الموظفين', (k) => _rangeKey = k),
              error: _showErrors && _rangeKey == null, errorText: 'اختر عدد الموظفين'),
          const SizedBox(height: 12),
          VField(label: 'بيانات التواصل', hint: 'رقم أو إيميل للتواصل', controller: _contact,
              error: _showErrors && _contact.text.trim().isEmpty, errorText: 'اكتب بيانات التواصل'),
          const SizedBox(height: 14),
          VButton(title: 'حفظ بيانات الجهة', onPressed: _busy ? null : _saveInfo),
          const SizedBox(height: 20),
          _uploadRow('اللوجو', _logo,
              () => _upload((p) => ProfileApi.instance.uploadOrgLogo(p.bytes, p.filename, p.mime), () => _logo = true)),
          ..._docs.entries.map((d) => _uploadRow(
              d.value,
              _uploaded.contains(d.key),
              () => _upload(
                  (p) => ProfileApi.instance.uploadOrgDocument(d.key, p.bytes, p.filename, p.mime),
                  () => _uploaded.add(d.key)))),
          if (o != null && !o.canSubmit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('كمّل البيانات واللوجو والمستندات الثلاثة عشان تقدر ترسل للمراجعة.',
                  textAlign: TextAlign.center, style: vText(size: 12, color: AppColors.TextSecondaryLight)),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(_error!, textAlign: TextAlign.center, style: vText(size: 12, color: AppColors.errorColor)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
