import 'package:flutter/widgets.dart';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedBytes {
  PickedBytes(this.bytes, this.filename, this.mime);
  final Uint8List bytes;
  final String filename;
  final String mime;
}

/// بيقرا الصورة المختارة ويحدد نوعها (jpg/png) للرفع.
Future<PickedBytes> readPicked(XFile f) async {
  final bytes = await f.readAsBytes();
  var name = f.name.isNotEmpty ? f.name : f.path.split('/').last;
  final lower = name.toLowerCase();
  final isPng = lower.endsWith('.png');
  if (!isPng && !lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
    name = '$name.jpg';
  }
  return PickedBytes(bytes, name, isPng ? 'image/png' : 'image/jpeg');
}

/// معاينة صورة مختارة. بتشتغل على الموبايل والويب (Image.file مش شغال على الويب).
class PickedImage extends StatelessWidget {
  const PickedImage(this.file, {super.key, this.width, this.height});
  final XFile file;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (_, s) => s.hasData
          ? Image.memory(s.data!, fit: BoxFit.cover, width: width, height: height)
          : SizedBox(width: width, height: height),
    );
  }
}
