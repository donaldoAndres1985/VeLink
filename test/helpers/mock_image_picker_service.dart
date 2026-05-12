import 'package:velink/features/capture/services/image_picker_service.dart';

class MockImagePickerService implements ImagePickerService {
  final String? galleryPath;
  final String? cameraPath;
  final bool shouldThrow;

  MockImagePickerService({
    this.galleryPath,
    this.cameraPath,
    this.shouldThrow = false,
  });

  @override
  Future<String?> pickFromGallery() async {
    if (shouldThrow) throw Exception('Permission denied');
    return galleryPath;
  }

  @override
  Future<String?> pickFromCamera() async {
    if (shouldThrow) throw Exception('Permission denied');
    return cameraPath;
  }
}
