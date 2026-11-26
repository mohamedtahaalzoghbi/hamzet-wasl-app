import 'package:flutter/material.dart';


import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../core/usersection.dart';
import '../../../widgets/volunteerwidgets.dart';
import 'LocationScreen.dart';


class HelpTypeScreen extends StatefulWidget {
  const HelpTypeScreen({super.key});

  @override
  State<HelpTypeScreen> createState() => _HelpTypeScreenState();
}

class _HelpOption {
  const _HelpOption(this.title, this.subtitle);
  final String title;
  final String subtitle;
}

class _HelpTypeScreenState extends State<HelpTypeScreen> {
  int? _selected;

  static const _options = [
    _HelpOption('أونلاين فقط', 'مساعدة عن بعد\n(مكالمات - شرح - فيديو)'),
    _HelpOption(
      'أونلاين وأوفلاين',
      'مساعدة عن بعد ووجهًا لوجه\n(مع تحديد موقعك)',
    ),
  ];

  bool _busy = false;

  Future<void> _next() async {
    if (_busy) return;
    UserSession.isOffline = _selected == 1;
    setState(() => _busy = true);
    try {
      await ProfileApi.instance.saveVolunteerProfile(
        introduction: UserSession.about,
        helpMode: _selected == 1 ? 'online_and_field' : 'online_only',
        skillLevel: UserSession.volunteerSkillLevel,
        weeklyHours: UserSession.volunteerWeeklyHours,
        experienceNotes: UserSession.volunteerExperience,
        skillIds: UserSession.skillIds.toList(),
      );
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

    if (_selected == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LocationScreen()),
      );
    } else {
      // TODO: أونلاين فقط - وجّهي للصفحة الرئيسية لما تتعمل
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ اختيارك', style: vText(size: 13, color: Colors.white))),
      );
    }
  }

  Widget _card(int index) {
    final option = _options[index];
    final selected = _selected == index;

    return GestureDetector(
      onTap: () => setState(() => _selected = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.softGreen : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary_button : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(option.title, style: vText(size: 16, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              option.subtitle,
              textAlign: TextAlign.center,
              style: vText(size: 12, color: AppColors.TextSecondaryLight, height: 1.6),
            ),
          ],
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
        onPressed: (_selected == null || _busy) ? null : _next,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Center(
            child: Text(
              'اختار نوع المساعدة ويمكن تغييرها لاحقا',
              style: vText(size: 14, weight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          _card(0),
          _card(1),
        ],
      ),
    );
  }
}

