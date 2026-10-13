import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class ProfilePhotoPicker {
  Future<Uint8List?> pick();
  Future<Uint8List?> recover();
}

class GalleryProfilePhotoPicker implements ProfilePhotoPicker {
  final _picker = ImagePicker();

  Future<Uint8List> _read(XFile file) async {
    if (await file.length() > 5 * 1024 * 1024) {
      throw const FormatException('Foto maksimal 5 MB.');
    }
    final bytes = await file.readAsBytes();
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes, targetWidth: 112);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      return bytes;
    } catch (_) {
      throw const FormatException('File foto tidak dapat dibaca.');
    } finally {
      codec?.dispose();
    }
  }

  @override
  Future<Uint8List?> pick() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    return file == null ? null : _read(file);
  }

  @override
  Future<Uint8List?> recover() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    final result = await _picker.retrieveLostData();
    if (result.exception != null) throw result.exception!;
    final files = result.files;
    return files == null || files.isEmpty ? null : _read(files.first);
  }
}
