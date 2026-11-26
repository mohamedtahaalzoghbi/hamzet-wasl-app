import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../core/usersection.dart';
import 'interview_screen.dart';
import '../../../widgets/volunteerwidgets.dart';

class _Platform {
  const _Platform({
    required this.key,
    required this.name,
    required this.addTitle,
    required this.subtitle,
    required this.color,
    required this.example,
    required this.asset,
    this.glyph = '',
    this.icon,
  });

  final String key;
  final String name;
  final String addTitle;
  final String subtitle;
  final Color color;
  final String example;
  final String asset;
  final String glyph;
  final IconData? icon;
}

const _platforms = [
  _Platform(
    key: 'facebook',
    name: 'فيسبوك',
    addTitle: 'إضافة فيسبوك',
    subtitle: 'أضف رابط حسابك على فيسبوك',
    color: Color(0xFF1877F2),
    example: 'facebook.com/username',
    asset: 'assets/PlatformIcon (3).png',
    glyph: 'f',
  ),
  _Platform(
    key: 'linkedin',
    name: 'لينكدإن',
    addTitle: 'إضافة لينكدإن',
    subtitle: 'أضف رابط حسابك على لينكدإن',
    color: Color(0xFF0A66C2),
    example: 'linkedin.com/in/username',
    asset: 'assets/PlatformIcon (4).png',
    glyph: 'in',
  ),
  _Platform(
    key: 'instagram',
    name: 'إنستغرام',
    addTitle: 'إضافة إنستغرام',
    subtitle: 'أضف رابط حسابك على إنستغرام',
    color: Color(0xFFE1306C),
    example: 'instagram.com/username',
    asset: 'assets/PlatformIcon (5).png',
    icon: Icons.camera_alt_outlined,
  ),
];

/// أيقونة المنصة: بتعرض الصورة، ولو مش لاقياها بترجع للمربع الملون.
Widget _brandBox(_Platform p, {double size = 50}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.asset(
      p.asset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: p.color,
        child: p.icon != null
            ? Icon(p.icon, color: Colors.white, size: size * 0.55)
            : Text(
          p.glyph,
          style: GoogleFonts.cairo(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

class SocialAccountsScreen extends StatefulWidget {
  const SocialAccountsScreen({super.key});

  @override
  State<SocialAccountsScreen> createState() => _SocialAccountsScreenState();
}

class _SocialAccountsScreenState extends State<SocialAccountsScreen> {
  Future<void> _edit(_Platform p) async {
    final link = await showVSheet<String>(
      context,
      builder: (_) => _LinkSheet(
        platform: p,
        initial: UserSession.socialLinks[p.key],
      ),
    );
    if (link != null) {
      setState(() => UserSession.socialLinks[p.key] = link);
    }
  }

  bool _busy = false;

  Future<void> _next() async {
    if (_busy) return;
    if (UserSession.socialLinks.values.every((v) => v.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اربط حساب تواصل واحد على الأقل قبل المتابعة', style: vText(size: 13, color: Colors.white))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await ProfileApi.instance.saveSocialLinks(Map<String, String>.from(UserSession.socialLinks));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e), style: vText(size: 13, color: Colors.white))),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const InterviewScreen()));
  }

  Widget _card(_Platform p) {
    final link = UserSession.socialLinks[p.key];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEDED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _brandBox(p),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: vText(size: 15, weight: FontWeight.w700)),
                    Text(
                      p.subtitle,
                      style: vText(size: 11, color: AppColors.TextSecondaryLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _edit(p),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 36,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.link,
                    size: 16,
                    color: AppColors.primary_button,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    link == null ? 'إضافة رابط' : 'تعديل الرابط',
                    style: vText(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.primary_button,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (link != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  link,
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: vText(size: 11, color: AppColors.TextSecondaryLight),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'حسابات التواصل الاجتماعي',
      bottom: VButton(title: 'التالي', onPressed: _busy ? null : _next),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),
          Center(
            child: Text(
              'ضيف لينكاتك للتعرف عليك أكتر',
              style: vText(size: 14, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          ..._platforms.map(_card),
          const SizedBox(height: 4),
          Text(
            'تُستخدم هذه الروابط لأغراض مراجعة طلب التطوع فقط.',
            style: vText(size: 11, color: AppColors.TextSecondaryLight),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ───────────────────── Add link sheet ─────────────────────

class _LinkSheet extends StatefulWidget {
  const _LinkSheet({required this.platform, this.initial});
  final _Platform platform;
  final String? initial;

  @override
  State<_LinkSheet> createState() => _LinkSheetState();
}

class _LinkSheetState extends State<_LinkSheet> {
  late final TextEditingController _ctrl =
  TextEditingController(text: widget.initial ?? '');
  bool _showError = false;

  bool get _valid {
    final t = _ctrl.text.trim();
    return t.length >= 4 && t.contains('.');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    setState(() => _showError = true);
    if (!_valid) return;
    Navigator.pop(context, _ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.platform;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const VSheetHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  _brandBox(p, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.addTitle,
                          style: vText(size: 16, weight: FontWeight.w700),
                        ),
                        Text(
                          'أدخل رابط حسابك الشخصي',
                          style: vText(
                            size: 11,
                            color: AppColors.TextSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VCloseButton(),
                ],
              ),
              const SizedBox(height: 16),
              VField(
                label: 'رابط الحساب',
                hint: 'أدخل رابط حسابك هنا',
                controller: _ctrl,
                icon: Icons.link,
                keyboardType: TextInputType.url,
                ltr: true,
                error: _showError && !_valid,
                errorText: 'اكتب رابط صحيح',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 4),
              Text(
                '${p.example}: مثال',
                textDirection: TextDirection.ltr,
                style: vText(size: 10, color: AppColors.TextSecondaryLight),
              ),
              const SizedBox(height: 16),
              VButton(title: 'حفظ الرابط', onPressed: _save),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'إلغاء',
                  style: vText(size: 13, color: AppColors.TextSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
