import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressor {
  static const _maxBytes = 2 * 1024 * 1024; // 2 MB
  static const _quality = 70;
  static const _maxWidth = 1920;

  static Future<File> compress(File file) async {
    final size = await file.length();
    final ext = file.path.split('.').last.toLowerCase();

    if (ext == 'pdf' || size <= _maxBytes) return file;

    try {
      final dir = await getTemporaryDirectory();
      final target = '${dir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        target,
        quality: _quality,
        minWidth: _maxWidth,
        keepExif: true,
      );

      if (result != null) {
        return File(result.path);
      }
    } catch (_) {}

    return file;
  }
}
