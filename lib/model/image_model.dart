import 'dart:typed_data';

class ImageModel {
  final Uint8List image;
  final String mimeType;

  ImageModel({required this.image, required this.mimeType});

  @override
  String toString() => 'ImageModel(image:$image, mimeType: $mimeType)';
}
