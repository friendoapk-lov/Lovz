import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;

// Ek data class jo alag-alag compressed versions ko sambhalegi
class ProcessedImage {
  final String baseName; // Unique naam bina extension ke (e.g., userid-uuid)
  final String originalFileName; // Poora original naam (e.g., userid-uuid_original.jpg)
  final String mediumFileName;   // Poora medium naam (e.g., userid-uuid_medium.webp)
  final String thumbFileName;    // Poora thumbnail naam (e.g., userid-uuid_thumb.webp)
  
  // Asli compressed data
  final Uint8List originalBytes;
  final Uint8List mediumBytes;
  final Uint8List thumbBytes;

  ProcessedImage({
    required this.baseName,
    required this.originalFileName,
    required this.mediumFileName,
    required this.thumbFileName,
    required this.originalBytes,
    required this.mediumBytes,
    required this.thumbBytes,
  });
}

// YEH FUNCTION BACKGROUND (ISOLATE) ME CHALEGA
// Naya, saaf, aur sahi function
Future<ProcessedImage> processImageForUpload(String filePath, String baseName) async {
  final File imageFile = File(filePath);
  final String originalExtension = p.extension(imageFile.path);

  // 1. Original Image (Bytes)
  final Uint8List originalBytes = await imageFile.readAsBytes();

  // 2. Medium Image (1080px, quality 80, webp)
  final Uint8List mediumBytes = await FlutterImageCompress.compressWithFile(
    imageFile.absolute.path,
    minWidth: 1080,
    minHeight: 1080,
    quality: 80,
    format: CompressFormat.webp,
  ) ?? Uint8List(0);

  // 3. Thumbnail Image (200px, quality 75, webp)
  final Uint8List thumbBytes = await FlutterImageCompress.compressWithFile(
    imageFile.absolute.path,
    minWidth: 200,
    minHeight: 200,
    quality: 75,
    format: CompressFormat.webp,
  ) ?? Uint8List(0);

  return ProcessedImage(
    baseName: baseName,
    originalFileName: '${baseName}_original$originalExtension',
    mediumFileName: '${baseName}_medium.webp',
    thumbFileName: '${baseName}_thumb.webp',
    originalBytes: originalBytes,
    mediumBytes: mediumBytes,
    thumbBytes: thumbBytes,
  );
}