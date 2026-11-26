import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../widgets/Colors.dart';
import '../../../widgets/volunteerwidgets.dart';

/// حجز مقابلة التحقق: بيعرض المواعيد المتاحة من السيرفر ويحجز الموعد المختار.
class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key});

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  List<InterviewSlot>? _slots;
  String? _error;
  String? _selected;
  bool _busy = false;
  bool _booked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _slots = null;
    });
    try {
      final s = await ProfileApi.instance.interviewSlots();
      if (mounted) setState(() => _slots = s);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    }
  }

  Future<void> _book() async {
    if (_selected == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProfileApi.instance.bookInterview(_selected!);
      if (mounted) setState(() => _booked = true);
    } catch (e) {
      if (mounted) setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(InterviewSlot s) {
    final t = s.startsAt?.toLocal();
    if (t == null) return s.id;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}/${two(t.month)}/${two(t.day)}  ${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final slots = _slots;
    Widget content;
    if (_booked) {
      final chosen = slots?.where((x) => x.id == _selected).toList() ?? [];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.check_circle_outline, size: 72, color: AppColors.primary_button),
          const SizedBox(height: 16),
          Text('تم حجز المقابلة', textAlign: TextAlign.center, style: vText(size: 20, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (chosen.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('موعدك: ${_label(chosen.first)}',
                  textAlign: TextAlign.center, style: vText(size: 15, weight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          Text('هنراجع طلبك ونبلغك.', textAlign: TextAlign.center, style: vText(size: 14)),
          const SizedBox(height: 28),
          VButton(title: 'الرجوع للرئيسية', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
        ],
      );
    } else if (slots == null && _error == null) {
      content = const Center(child: CircularProgressIndicator());
    } else if (slots == null || slots.isEmpty) {
      content = Column(children: [
        const SizedBox(height: 40),
        Text(_error ?? 'مفيش مواعيد مقابلة متاحة دلوقتي. جرّب تاني بعد شوية.',
            textAlign: TextAlign.center, style: vText(size: 14)),
        const SizedBox(height: 16),
        VButton(title: 'تحديث', onPressed: _load),
      ]);
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          ...slots.map((s) {
            final on = _selected == s.id;
            return GestureDetector(
              onTap: () => setState(() => _selected = s.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: on ? AppColors.softGreen : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: on ? AppColors.primary_button : AppColors.border),
                ),
                child: Text(_label(s), textAlign: TextAlign.center, style: vText(size: 14, weight: FontWeight.w600)),
              ),
            );
          }),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, textAlign: TextAlign.center, style: vText(size: 12, color: AppColors.errorColor)),
            ),
        ],
      );
    }
    return VolunteerScaffold(
      title: 'حجز مقابلة التحقق',
      bottom: (_booked || slots == null || slots.isEmpty)
          ? null
          : VButton(title: 'احجز الموعد', onPressed: (_selected == null || _busy) ? null : _book),
      body: content,
    );
  }
}
