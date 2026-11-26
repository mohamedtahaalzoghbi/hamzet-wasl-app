import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/profile_api.dart';
import '../../core/usersection.dart';
import '../../widgets/Colors.dart';
import '../../widgets/volunteerwidgets.dart';
import 'account_setup_widgets.dart';
import 'volunteer/volunteer_info_screen.dart';

class NeedCategoryScreen extends StatefulWidget {
  const NeedCategoryScreen({super.key});

  @override
  State<NeedCategoryScreen> createState() => _NeedCategoryScreenState();
}

class _NeedOption {
  const _NeedOption(this.category, this.title, this.subtitle, this.icon);

  final NeedCategory category;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _NeedCategoryScreenState extends State<NeedCategoryScreen> {
  static const _selectedBorder = Color(0xFF5C4636);
  static const _iconColor = Color(0xFF6F9A90);

  static const _options = [
    _NeedOption(
      NeedCategory.mobility,
      'حركية',
      'إعدادات وتفضيلات إتاحة حركية',
      Icons.accessible,
    ),
    _NeedOption(
      NeedCategory.visual,
      'بصرية',
      'إعدادات وتفضيلات إتاحة بصرية',
      Icons.visibility_outlined,
    ),
    _NeedOption(
      NeedCategory.hearing,
      'سمعية',
      'إعدادات وتفضيلات إتاحة سمعية',
      Icons.hearing,
    ),
  ];

  NeedCategory? _selected;

  @override
  void initState() {
    super.initState();
    _selected = UserSession.needCategory;
  }

  bool _busy = false;

  static String _needType(NeedCategory c) {
    switch (c) {
      case NeedCategory.mobility:
        return 'motor';
      case NeedCategory.visual:
        return 'visual';
      case NeedCategory.hearing:
        return 'hearing';
    }
  }

  Future<void> _finish() async {
    if (_busy) return;
    UserSession.needCategory = _selected;
    // إعدادات الإتاحة بتتحفظ لحساب "ذوي همم" فقط (السيرفر بيرفض باقي الأدوار).
    if (_selected != null && UserSession.accountKind == AccountKind.interested) {
      setState(() => _busy = true);
      try {
        await ProfileApi.instance.setAccessibility(_needType(_selected!));
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
    }
    if (UserSession.accountKind == AccountKind.volunteer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VolunteerProfileScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ بياناتك',
          style: vText(size: 13, color: Colors.white),
        ),
      ),
    );
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
              AccountSetupHeader(
                title: 'اختار فئة احتياجك',
                showBack: true,
                onSkip: _finish,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    children: [
                      Text(
                        'اختار فئة أو أكثر عشان نضبط تجربة الإتاحة.\nالاختيارات دي خاصة وقابلة للتعديل.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.7,
                          color: AppColors.TextSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 22),
                      for (final option in _options)
                        _NeedCard(
                          option: option,
                          selected: _selected == option.category,
                          selectedBorder: _selectedBorder,
                          iconColor: _iconColor,
                          onTap: () => setState(() => _selected = option.category),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SetupContinueButton(
                  title: 'متابعة',
                  onPressed: _finish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedCard extends StatelessWidget {
  const _NeedCard({
    required this.option,
    required this.selected,
    required this.selectedBorder,
    required this.iconColor,
    required this.onTap,
  });

  final _NeedOption option;
  final bool selected;
  final Color selectedBorder;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? selectedBorder : const Color(0xFFE4E4E4),
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(option.icon, size: 28, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.PremaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.TextSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _RadioDot(selected: selected, color: selectedBorder),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? color : Colors.transparent,
        border: Border.all(
          color: selected ? color : const Color(0xFFD5D5D5),
          width: 1.6,
        ),
      ),
    );
  }
}

