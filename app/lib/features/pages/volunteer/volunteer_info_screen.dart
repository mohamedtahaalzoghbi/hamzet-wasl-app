
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:graduation_project/core/api/api_exception.dart';
import 'package:graduation_project/core/api/profile_api.dart';
import 'package:graduation_project/core/api/upload_util.dart';
import 'package:graduation_project/core/usersection.dart';
import 'package:graduation_project/widgets/Colors.dart';
import 'package:graduation_project/widgets/choice_sheets.dart';
import 'package:graduation_project/widgets/volunteerwidgets.dart';
import 'helpType.dart';

class VolunteerProfileScreen extends StatefulWidget {
  const VolunteerProfileScreen({super.key});

  @override
  State<VolunteerProfileScreen> createState() =>
      _VolunteerProfileScreenState();
}

class _VolunteerProfileScreenState extends State<VolunteerProfileScreen> {
  final _bio = TextEditingController();
  final _areas = TextEditingController();
  final _skills = TextEditingController();
  final _experience = TextEditingController();
  final _hours = TextEditingController();

  static const _levels = ['مبتدئ', 'متوسط', 'متقدم'];

  static const _hoursOptions = [
    'من 1 إلى 3 ساعات',
    'من 4 إلى 6 ساعات',
    'من 7 إلى 10 ساعات',
    'أكثر من 10 ساعات',
  ];

  String? _level;
  XFile? _photo;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _skillIds = {...UserSession.skillIds};
    if (_skillIds.isNotEmpty) {
      ProfileApi.instance.skills().then((items) {
        if (!mounted || _skills.text.isNotEmpty) return;
        setState(() => _skills.text =
            items.where((i) => _skillIds.contains(i.id)).map((i) => i.name).join('، '));
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _bio.dispose();
    _areas.dispose();
    _skills.dispose();
    _experience.dispose();
    _hours.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() => _photo = picked);
      }
    } catch (e) {
      debugPrint('pickPhoto error: $e');
    }
  }

  Future<void> _pickHours() async {
    final result = await showVSheet<String>(
      context,
      builder: (ctx) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSheetHandle(),
            const VSheetTitle(title: 'ساعات التطوع أسبوعياً'),
            ..._hoursOptions.map((h) {
              final selected = _hours.text == h;
              return ListTile(
                onTap: () => Navigator.pop(ctx, h),
                title: Text(
                  h,
                  style: vText(
                    size: 14,
                    weight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color:
                  selected ? AppColors.primary_button : AppColors.border,
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() => _hours.text = result);
    }
  }

  bool _busy = false;
  Set<int> _skillIds = {};
  Set<int> _interestIds = {};

  Future<void> _chooseSkills() async {
    final items = await ProfileApi.instance.skills().catchError((_) => <MetaItem>[]);
    if (!mounted) return;
    if (items.isEmpty) return _snack('مقدرناش نحمّل المهارات من السيرفر. حاول تاني.');
    final r = await showVSheet<Set<int>>(context,
        builder: (_) => MultiChoiceSheet(title: 'المهارات', items: items, initial: _skillIds));
    if (r == null) return;
    setState(() {
      _skillIds = r;
      _skills.text = items.where((i) => r.contains(i.id)).map((i) => i.name).join('، ');
    });
  }

  Future<void> _chooseInterests() async {
    final items = await ProfileApi.instance.interests().catchError((_) => <MetaItem>[]);
    if (!mounted) return;
    if (items.isEmpty) return _snack('مقدرناش نحمّل المجالات من السيرفر. حاول تاني.');
    final r = await showVSheet<Set<int>>(context,
        builder: (_) => MultiChoiceSheet(title: 'مجالات المساعدة', items: items, initial: _interestIds));
    if (r == null) return;
    setState(() {
      _interestIds = r;
      _areas.text = items.where((i) => r.contains(i.id)).map((i) => i.name).join('، ');
    });
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m, style: vText(size: 13, color: Colors.white))));

  static const _levelKeys = {
    'مبتدئ': 'beginner',
    'متوسط': 'intermediate',
    'متقدم': 'advanced',
  };
  // الحد الأعلى لكل اختيار ساعات
  static const _hoursValue = {
    'من 1 إلى 3 ساعات': 3,
    'من 4 إلى 6 ساعات': 6,
    'من 7 إلى 10 ساعات': 10,
    'أكثر من 10 ساعات': 12,
  };

  Future<void> _next() async {
    if (_busy) return;
    setState(() => _showError = true);

    if (_bio.text.trim().isEmpty ||
        _skills.text.trim().isEmpty ||
        _hours.text.trim().isEmpty ||
        _level == null) {
      return;
    }

    // بيانات الملف بتتبعت (PUT /me/volunteer-profile) في الخطوة الجاية مع نوع المساعدة
    // لأن الباك بيطلب helpMode في نفس الطلب.
    UserSession.about = _bio.text.trim();
    UserSession.skillIds = _skillIds;
    UserSession.interestIds = _interestIds;
    UserSession.volunteerSkillLevel = _levelKeys[_level] ?? 'beginner';
    UserSession.volunteerWeeklyHours = _hoursValue[_hours.text.trim()] ?? 3;
    UserSession.volunteerExperience = _experience.text.trim();

    setState(() => _busy = true);
    try {
      if (_photo != null) {
        final p = await readPicked(_photo!);
        await ProfileApi.instance.uploadAvatar(p.bytes, p.filename, p.mime);
      }
      await ProfileApi.instance.updateProfile(bio: UserSession.about);
      if (_interestIds.isNotEmpty) {
        await ProfileApi.instance.setInterests(_interestIds.toList());
      }
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _snack(apiErrorMessage(e));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HelpTypeScreen(),
      ),
    );
  }

  Widget _levelChip(String level) {
    final selected = _level == level;

    return GestureDetector(
      onTap: () {
        setState(() {
          _level = level;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary_button : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary_button : AppColors.border,
          ),
        ),
        child: Text(
          level,
          style: vText(
            size: 15,
            weight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.PremaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'خلينا نتعرف عليك اكتر',
      bottom: VButton(
        title: 'التالي',
        onPressed: _busy ? null : _next,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // الصورة الشخصية
          Center(
            child: GestureDetector(
              onTap: _pickPhoto,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipOval(
                    child: _photo != null
                        ? PickedImage(_photo!, width: 171, height: 171)
                        : Image.asset(
                      'assets/profile.png',
                      height: 171,
                      width: 171,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Center(
            child: Text(
              'الصورة الشخصية',
              style: vText(
                size: 12,
                weight: FontWeight.w600,
              ),
            ),
          ),

          Center(
            child: Text(
              'اختياري - JPG أو PNG',
              style: vText(
                size: 10,
                color: AppColors.TextSecondaryLight,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // نبذة شخصية
          VField(
            label: 'نبذة شخصية',
            hint: 'اكتبلنا عن خبرتك ودافعك للتطوع',
            controller: _bio,
            maxLines: 4,
            error: _showError && _bio.text.trim().isEmpty,
            errorText: 'اكتب نبذة قصيرة عنك',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // مجالات المساعدة
          VField(
            label: 'مجالات المساعدة',
            hint: 'المجالات اللي تهمك',
            controller: _areas,
            readOnly: true,
            onTap: _chooseInterests,
          ),

          const SizedBox(height: 14),

          // المهارات
          VField(
            label: 'المهارات',
            hint: 'مهاراتك اللي يمكنك مساعدة الآخرين بها',
            controller: _skills,
            readOnly: true,
            onTap: _chooseSkills,
            error: _showError && _skills.text.trim().isEmpty,
            errorText: 'اكتب مهارة واحدة على الأقل',
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 14),

          // الخبرات والشهادات
          VField(
            label: 'الخبرات والشهادات',
            hint: 'اكتب خبراتك أو أضف رابط الشهادة',
            controller: _experience,
          ),

          const SizedBox(height: 14),

          // مستوى المهارة
          Text(
            'مستوى المهارة',
            style: vText(
              size: 14,
              weight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _levels.map(_levelChip).toList(),
          ),

          // رسالة الخطأ عند عدم اختيار المستوى
          if (_showError && _level == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'يرجى اختيار مستوى المهارة',
                textAlign: TextAlign.right,
                style: vText(
                  size: 11,
                  color: Colors.red,
                ),
              ),
            ),

          const SizedBox(height: 14),

          // ساعات التطوع (قايمة)
          VField(
            label: 'ساعات التطوع أسبوعياً',
            hint: 'اختر عدد الساعات المتاحة',
            controller: _hours,
            readOnly: true,
            onTap: _pickHours,
            suffix: const Icon(Icons.keyboard_arrow_down),
            error: _showError && _hours.text.trim().isEmpty,
            errorText: 'حدد عدد الساعات المتاحة',
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
