import 'package:flutter/material.dart';

import '../core/api/profile_api.dart';
import 'Colors.dart';
import 'volunteerwidgets.dart';

/// شيت اختيار متعدد (مهارات / مجالات) من قائمة جاية من السيرفر.
class MultiChoiceSheet extends StatefulWidget {
  const MultiChoiceSheet({
    super.key,
    required this.title,
    required this.items,
    required this.initial,
  });

  final String title;
  final List<MetaItem> items;
  final Set<int> initial;

  @override
  State<MultiChoiceSheet> createState() => _MultiChoiceSheetState();
}

class _MultiChoiceSheetState extends State<MultiChoiceSheet> {
  late final Set<int> _sel = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const VSheetHandle(),
          VSheetTitle(title: widget.title),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.items.map((i) {
                  final on = _sel.contains(i.id);
                  return FilterChip(
                    label: Text(i.name, style: vText(size: 13)),
                    selected: on,
                    selectedColor: AppColors.softGreen,
                    onSelected: (v) =>
                        setState(() => v ? _sel.add(i.id) : _sel.remove(i.id)),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          VButton(title: 'حفظ', onPressed: () => Navigator.pop(context, _sel)),
        ],
      ),
    );
  }
}

/// شيت اختيار واحد من قائمة نصوص.
class SingleChoiceSheet extends StatelessWidget {
  const SingleChoiceSheet({super.key, required this.title, required this.options});
  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Column(
        children: [
          const VSheetHandle(),
          VSheetTitle(title: title),
          Expanded(
            child: ListView(
              children: options
                  .map((o) => ListTile(
                        title: Text(o, style: vText(size: 14)),
                        onTap: () => Navigator.pop(context, o),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// تحميل قائمة من السيرفر وفتح شيت الاختيار المتعدد. بيرجع null لو اتلغى/فشل.
Future<Set<int>?> pickMulti(
  BuildContext context, {
  required String title,
  required Future<List<MetaItem>> Function() load,
  required Set<int> initial,
}) async {
  List<MetaItem> items;
  try {
    items = await load();
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('مقدرناش نحمّل القائمة من السيرفر. حاول تاني.',
            style: vText(size: 13, color: Colors.white)),
      ));
    }
    return null;
  }
  if (!context.mounted) return null;
  return showVSheet<Set<int>>(
    context,
    builder: (_) => MultiChoiceSheet(title: title, items: items, initial: initial),
  );
}
