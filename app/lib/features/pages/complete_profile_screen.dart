import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/profile_api.dart';
import '../../core/usersection.dart';
import '../../widgets/choice_sheets.dart';
import '../../widgets/Colors.dart';
import '../../widgets/volunteerwidgets.dart';
import 'account_setup_widgets.dart';
import 'need_category_screen.dart';
import 'volunteer/volunteer_info_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  Future<void> _editSection({
    required String title,
    required String hint,
    required String current,
    required void Function(String value) onSave,
  }) async {
    final saved = await showVSheet<String>(
      context,
      builder: (ctx) => _SectionSheet(
        title: title,
        hint: hint,
        initial: current,
      ),
    );
    if (saved == null) return;
    setState(() => onSave(saved));
  }

  bool _busy = false;

  void _snack(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m, style: vText(size: 13, color: Colors.white))));

  Future<void> _pickInterests() async {
    final r = await pickMulti(context,
        title: 'المجالات التي تهمك',
        load: ProfileApi.instance.interests,
        initial: UserSession.interestIds);
    if (r != null) setState(() => UserSession.interestIds = r);
  }

  Future<void> _pickSkills() async {
    final r = await pickMulti(context,
        title: 'مهاراتك التي يمكنك مساعدة الآخرين بها',
        load: ProfileApi.instance.skills,
        initial: UserSession.skillIds);
    if (r != null) setState(() => UserSession.skillIds = r);
  }

  /// متابعة: بيحفظ النبذة والمجالات والمهارات على الباك ثم يكمل.
  Future<void> _saveAndContinue() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (UserSession.about.trim().isNotEmpty) {
        await ProfileApi.instance.updateProfile(bio: UserSession.about.trim());
      }
      if (UserSession.interestIds.isNotEmpty) {
        await ProfileApi.instance.setInterests(UserSession.interestIds.toList());
      }
      if (UserSession.skillIds.isNotEmpty) {
        await ProfileApi.instance.setSkills(UserSession.skillIds.toList());
      }
    } catch (e) {
      if (mounted) _snack(apiErrorMessage(e));
      if (mounted) setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    _openNeedCategory();
  }

  void _openNeedCategory() {
    final Widget next = UserSession.accountKind == AccountKind.volunteer
        ? const VolunteerProfileScreen()
        : const NeedCategoryScreen();
    Navigator.push(context, MaterialPageRoute(builder: (_) => next));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              AccountSetupHeader(onSkip: _openNeedCategory),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      const _ProfileAvatar(),
                      const SizedBox(height: 22),
                      Text(
                        'أكمل ملفك الشخصى',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.PremaryText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ساعدنا في التعرف عليك بشكل أفضل\nوكيف يمكنك مساعده الآخرين',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.6,
                          color: AppColors.TextSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _ProfileRow(
                        title: 'نبذه عن نفسك',
                        onTap: () => _editSection(
                          title: 'نبذه عن نفسك',
                          hint: 'اكتبلنا نبذة قصيرة عنك',
                          current: UserSession.about,
                          onSave: (value) => UserSession.about = value,
                        ),
                      ),
                      _ProfileRow(
                        title: 'المجالات التي تهمك',
                        onTap: _pickInterests,
                      ),
                      _ProfileRow(
                        title: 'مهاراتك التي يمكنك مساعدة الآخرين بها',
                        onTap: _pickSkills,
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SetupContinueButton(
                  title: 'متابعة',
                  onPressed: () {
                    if (!_busy) _saveAndContinue();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSheet extends StatefulWidget {
  const _SectionSheet({
    required this.title,
    required this.hint,
    required this.initial,
  });

  final String title;
  final String hint;
  final String initial;

  @override
  State<_SectionSheet> createState() => _SectionSheetState();
}

class _SectionSheetState extends State<_SectionSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VSheetHandle(),
          VSheetTitle(title: widget.title),
          TextField(
            controller: _controller,
            maxLines: 4,
            style: vText(size: 14),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: vText(size: 13, color: AppColors.TextSecondaryLight),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary_button),
              ),
            ),
          ),
          const SizedBox(height: 16),
          VButton(
            title: 'حفظ',
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      height: 132,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: const BoxDecoration(
              color: Color(0xFFF4E7DA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 72,
              color: Color(0xFF8EAEA6),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 22,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFBF6F1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE6D3C2)),
              ),
              child: const Icon(
                Icons.accessible,
                size: 20,
                color: AppColors.terracotta,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 58),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE4E4E4)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: GoogleFonts.cairo(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppColors.PremaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

