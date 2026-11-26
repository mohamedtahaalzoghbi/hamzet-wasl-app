
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../core/api/upload_util.dart';
import '../../../widgets/volunteerwidgets.dart';
import 'Decumentation.dart';


class SelfieScreen extends StatefulWidget {
  const SelfieScreen({super.key});

  @override
  State<SelfieScreen> createState() => _SelfieScreenState();
}

class _SelfieScreenState extends State<SelfieScreen> {
  XFile? _photo;

  Future<void> _capture() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (picked != null) setState(() => _photo = picked);
    } catch (e) {
      debugPrint('capture error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'مقدرناش نفتح الكاميرا، اتأكد من إذن الكاميرا',
            style: vText(size: 13, color: Colors.white),
          ),
        ),
      );
    }
  }

  bool _busy = false;

  Future<void> _next() async {
    if (_busy || _photo == null) return;
    setState(() => _busy = true);
    try {
      final p = await readPicked(_photo!);
      await ProfileApi.instance.uploadEvidence('face_photo', p.bytes, p.filename, p.mime);
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
      MaterialPageRoute(builder: (_) => const DocumentsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'صورة أمامية لوجهك',
      bottom: VButton(
        title: 'التالي',
        onPressed: (_photo == null || _busy) ? null : _next,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          const VStepsBar(current: 3, total: 5),
          const SizedBox(height: 20),
          Text(
            'نحتاج إلى صورة واضحة للتأكد من هويتك واستكمال إجراءات التحقق',
            style: vText(size: 14, weight: FontWeight.w700, height: 1.6),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                SizedBox(
                  width: 190,
                  height: 190,
                  child: DashedBorder(
                    circle: true,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipOval(
                        child: _photo != null
                            ? PickedImage(_photo!)
                            : const AssetOrIcon(
                          asset: 'assets/SelfieIllustration.png',
                          fallback: Icons.face_outlined,
                          size: 170,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'متطلبات: السماح باستخدام الكاميرا',
                  style: vText(size: 10, color: AppColors.TextSecondaryLight),
                ),
                const SizedBox(height: 12),
                VButton(
                  title: _photo == null ? 'التقط صورة' : 'إعادة الالتقاط',
                  icon: Icons.camera_alt_outlined,
                  color: AppColors.terracotta,
                  onPressed: _capture,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'تُستخدم صورتك للتحقق من هويتك، ويتم التعامل معها بسرية.',
            style: vText(size: 11, color: AppColors.TextSecondaryLight),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

