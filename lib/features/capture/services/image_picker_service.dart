import 'package:image_picker/image_picker.dart';

abstract class ImagePickerService {
  Future<String?> pickFromGallery();
  Future<String?> pickFromCamera();
}

class ImagePickerServiceImpl implements ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<String?> pickFromGallery() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return file?.path;
  }

  @override
  Future<String?> pickFromCamera() async {
    final file = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    return file?.path;
  }
}
