
import 'package:flutter/material.dart';

import 'package:graduation_project/widgets/Colors.dart';
import 'package:graduation_project/widgets/auth_widgets.dart';

import 'package:geolocator/geolocator.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../core/usersection.dart';
import '../../../widgets/choice_sheets.dart';
import '../../../widgets/volunteerwidgets.dart';
import 'identify_info.dart';

const List<String> kGovernorates = [
  'القاهرة',
  'الجيزة',
  'الإسكندرية',
  'الدقهلية',
  'الشرقية',
  'الغربية',
  'المنوفية',
  'القليوبية',
  'كفر الشيخ',
  'دمياط',
  'البحيرة',
  'الفيوم',
  'بني سويف',
  'المنيا',
  'أسيوط',
  'سوهاج',
  'قنا',
  'الأقصر',
  'أسوان',
  'البحر الأحمر',
  'الوادي الجديد',
  'مطروح',
  'شمال سيناء',
  'جنوب سيناء',
  'بورسعيد',
  'الإسماعيلية',
  'السويس',
];

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final _governorateCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();

  String? _governorate;

  int _radius = 0;
  bool _locationPicked = false;
  bool _showErrors = false;

  @override
  void dispose() {
    _governorateCtrl.dispose();
    _areaCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickGovernorate() async {
    final result = await showVSheet<String>(
      context,
      builder: (_) => _GovernorateSheet(
        selected: _governorate,
      ),
    );

    if (result != null) {
      setState(() {
        if (_governorate != result) _areaCtrl.clear();
        _governorate = result;
        _governorateCtrl.text = result;
      });
    }
  }

  Future<void> _pickRadius() async {
    final result = await showVSheet<int>(
      context,
      builder: (_) => _RadiusSheet(
        initial: _radius == 0 ? null : _radius,
      ),
    );

    if (result != null) {
      setState(() {
        _radius = result;
        _radiusCtrl.text = '$result كم';
      });
    }
  }

  double? _lat;
  double? _lng;

  // مفيش SDK خريطة في المشروع، فالتحديد بيتم من موقع الجهاز الحالي (geolocator).
  void _pickOnMap() => _useCurrentLocation();

  Future<void> _useCurrentLocation() async {
    String? problem;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        problem = 'شغّل خدمة الموقع في الجهاز وحاول تاني';
      } else {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
          problem = 'محتاجين إذن الموقع عشان نحدد مكانك';
        } else {
          final pos = await Geolocator.getCurrentPosition();
          if (!mounted) return;
          setState(() {
            _lat = pos.latitude;
            _lng = pos.longitude;
            _locationPicked = true;
          });
        }
      }
    } catch (_) {
      problem = 'مقدرناش نحدد موقعك. حاول تاني';
    }
    if (problem != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(problem, style: vText(size: 13, color: Colors.white))),
      );
    }
  }

  bool _busy = false;

  Future<void> _pickArea() async {
    if (_governorate == null) return;
    try {
      final all = await ProfileApi.instance.governorates();
      final g = all.where((x) => x.nameAr == _governorate).toList();
      if (!mounted) return;
      if (g.isEmpty || g.first.areas.isEmpty) return;
      final r = await showVSheet<String>(context,
          builder: (_) => SingleChoiceSheet(title: 'المنطقة', options: g.first.areas));
      if (r != null) setState(() => _areaCtrl.text = r);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(apiErrorMessage(e), style: vText(size: 13, color: Colors.white))),
      );
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _showErrors = true;
    });

    if (_radius == 0) {
      return;
    }

    UserSession.governorate = _governorate;
    UserSession.area = _areaCtrl.text.trim();
    UserSession.radiusKm = _radius;

    if (_governorate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('اختار المحافظة الأول', style: vText(size: 13, color: Colors.white))),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      // السيرفر بيقبل اسم المحافظة والمنطقة بالعربي من قايمة /meta/governorates.
      await ProfileApi.instance.saveVolunteerLocation(
        governorate: _governorate!,
        serviceArea: _areaCtrl.text.trim().isEmpty ? null : _areaCtrl.text.trim(),
        radiusKm: _radius,
        latitude: _lat,
        longitude: _lng,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IdentityIntroScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'تحديد الموقع',

      bottom: VButton(
        title: 'حفظ ومتابعة',
        onPressed: _busy ? null : _save,
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          Center(
            child: Text(
              'اختر المحافظة او حدد موقعك على الخريطة',
              style: vText(
                size: 14,
                weight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // المحافظة + المنطقة + نطاق المسافة
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEDEDED),
              ),
            ),
            child: Column(
              children: [
                VField(
                  label: 'المحافظة',
                  hint: 'اختر المحافظة',
                  controller: _governorateCtrl,
                  readOnly: true,
                  onTap: _pickGovernorate,
                  suffix: const Icon(
                    Icons.keyboard_arrow_down,
                  ),
                ),

                const SizedBox(height: 14),

                VField(
                  label: 'المنطقة',
                  hint: _governorate == null
                      ? 'اختر المحافظة أولاً'
                      : 'اختر المنطقة',
                  controller: _areaCtrl,
                  readOnly: true,
                  onTap: _pickArea,
                  enabled: _governorate != null,
                ),

                const SizedBox(height: 14),

                VField(
                  label: 'نطاق المسافة',
                  hint: 'اختر نطاق المسافة',
                  controller: _radiusCtrl,
                  readOnly: true,
                  onTap: _pickRadius,
                  suffix: const Icon(
                    Icons.keyboard_arrow_down,
                  ),
                  error: _showErrors && _radius == 0,
                  errorText: 'يجب تحديد نطاق المسافة',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // الخريطة
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFEDEDED),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الموقع على الخريطة',
                  style: vText(
                    size: 14,
                    weight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'اضغط لتحديد موقعك الحالي',
                  style: vText(
                    size: 11,
                    color: AppColors.TextSecondaryLight,
                  ),
                ),

                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 130,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          'assets/map_preview.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: AppColors.softGreen,
                              child: const Icon(
                                Icons.map_outlined,
                                size: 48,
                                color: AppColors.TextSecondaryDart,
                              ),
                            );
                          },
                        ),

                        Center(
                          child: GestureDetector(
                            onTap: _pickOnMap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppColors.primary_button,
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    _locationPicked
                                        ? 'تم تحديد الموقع'
                                        : 'حدد موقعي الحالي',
                                    style: vText(
                                      size: 12,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _useCurrentLocation,
                    icon: const Icon(
                      Icons.my_location,
                      size: 18,
                    ),
                    label: Text(
                      'استخدم موقعي الحالي',
                      style: vText(
                        size: 13,
                        weight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary_button,
                      side: const BorderSide(
                        color: authBorderColor,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ───────────────────── Governorate sheet ─────────────────────

class _GovernorateSheet extends StatefulWidget {
  const _GovernorateSheet({this.selected});

  final String? selected;

  @override
  State<_GovernorateSheet> createState() => _GovernorateSheetState();
}

class _GovernorateSheetState extends State<_GovernorateSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final list = kGovernorates
        .where((g) => g.contains(_query.trim()))
        .toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        children: [
          const VSheetHandle(),

          const VSheetTitle(
            title: 'اختر المحافظة',
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (v) {
                setState(() {
                  _query = v;
                });
              },
              style: vText(size: 13),
              decoration: authInputDecoration(
                hint: 'ابحث عن محافظة...',
              ).copyWith(
                hintStyle: vText(
                  size: 12,
                  color: authHintColor,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.TextSecondaryLight,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              itemCount: list.length,
              itemBuilder: (_, i) {
                final name = list[i];
                final selected = name == widget.selected;

                return ListTile(
                  onTap: () {
                    Navigator.pop(context, name);
                  },
                  title: Text(
                    name,
                    style: vText(
                      size: 14,
                      weight: selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  trailing: Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: selected
                        ? AppColors.primary_button
                        : AppColors.border,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────── Radius sheet ─────────────────────

class _RadiusSheet extends StatefulWidget {
  const _RadiusSheet({
    this.initial,
  });

  final int? initial;

  @override
  State<_RadiusSheet> createState() => _RadiusSheetState();
}

class _RadiusSheetState extends State<_RadiusSheet> {
  static const _presets = [5, 10, 20, 30, 50];

  int? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  Widget _chip(int v) {
    final selected = _value == v;

    return GestureDetector(
      onTap: () {
        setState(() {
          _value = v;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.terracottaSoft
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.terracotta
                : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$v كم',
          style: vText(
            size: 12,
            weight: selected
                ? FontWeight.w700
                : FontWeight.w500,
            color: selected
                ? AppColors.terracotta
                : AppColors.PremaryText,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const VSheetHandle(),

            const VSheetTitle(
              title: 'حدد نطاق المسافة',
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _value == null ? '--' : '$_value',
                  style: vText(
                    size: 44,
                    weight: FontWeight.w800,
                    color: AppColors.primary_button,
                    height: 1.2,
                  ),
                ),

                const SizedBox(width: 6),

                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'كم',
                    style: vText(
                      size: 16,
                      weight: FontWeight.w600,
                      color: AppColors.TextSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _presets.map(_chip).toList(),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'نطاق مخصص',
                style: vText(
                  size: 13,
                  weight: FontWeight.w600,
                ),
              ),
            ),

            Slider(
              value: (_value ?? 20).toDouble(),
              min: 1,
              max: 100,
              divisions: 99,
              activeColor: AppColors.terracotta,
              inactiveColor: AppColors.border,
              onChanged: (v) {
                setState(() {
                  _value = v.round();
                });
              },
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1 كم',
                  style: vText(
                    size: 11,
                    color: AppColors.TextSecondaryLight,
                  ),
                ),

                Text(
                  '100 كم',
                  style: vText(
                    size: 11,
                    color: AppColors.TextSecondaryLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            VButton(
              title: 'تأكيد النطاق',
              onPressed: _value == null
                  ? null
                  : () {
                Navigator.pop(context, _value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

