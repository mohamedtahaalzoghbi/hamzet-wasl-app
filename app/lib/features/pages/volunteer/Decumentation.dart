
import 'package:flutter/material.dart';
import 'package:graduation_project/features/pages/volunteer/socialAcount.dart';
import 'package:image_picker/image_picker.dart';

import 'package:graduation_project/widgets/Colors.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/profile_api.dart';
import '../../../core/api/upload_util.dart';
import '../../../widgets/volunteerwidgets.dart';


class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  XFile? _front;
  XFile? _back;

  Future<void> _pick({required bool front}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      setState(() => front ? _front = picked : _back = picked);
    } catch (e) {
      debugPrint('pick document error: $e');
    }
  }

  bool _busy = false;

  Future<void> _next() async {
    if (_busy || _front == null || _back == null) return;
    setState(() => _busy = true);
    try {
      final a = await readPicked(_front!);
      await ProfileApi.instance.uploadEvidence('national_id_front', a.bytes, a.filename, a.mime);
      final b = await readPicked(_back!);
      await ProfileApi.instance.uploadEvidence('national_id_back', b.bytes, b.filename, b.mime);
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
      MaterialPageRoute(builder: (_) => const SocialAccountsScreen()),
    );
  }

  Widget _uploadBox({
    required String label,
    required XFile? file,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: vText(size: 12, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: DashedBorder(
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.uploadFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: file != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PickedImage(file),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.border,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.file_upload_outlined,
                      size: 20,
                      color: AppColors.terracotta,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ارفع صورة',
                    style: vText(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.terracotta,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return VolunteerScaffold(
      title: 'تحميل المستندات',
      bottom: VButton(
        title: 'التالي',
        onPressed: (_front != null && _back != null && !_busy) ? _next : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: AssetOrIcon(
              asset: 'assets/decomentation.png',
              fallback: Icons.description_outlined,
              size: 120,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'المستندات المطلوبة',
            textAlign: TextAlign.center,
            style: vText(size: 16, weight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            'صورة البطاقة من الأمام والخلف',
            textAlign: TextAlign.center,
            style: vText(size: 13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _uploadBox(
            label: 'الوجه الأمامي',
            file: _front,
            onTap: () => _pick(front: true),
          ),
          const SizedBox(height: 14),
          _uploadBox(
            label: 'الوجه الخلفي',
            file: _back,
            onTap: () => _pick(front: false),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

