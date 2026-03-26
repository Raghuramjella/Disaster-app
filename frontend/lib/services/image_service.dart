import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';

class ImageService {
  static final _picker = ImagePicker();

  static Future<XFile?> pickFromGallery() =>
      _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

  static Future<XFile?> pickFromCamera() =>
      _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

  /// Uploads the after-disaster image for a claim and returns the stored URL.
  static Future<String> uploadAfterImage(int claimId, XFile image) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(image.path, filename: image.name),
    });
    final response = await ApiService.client.post(
      '/images/upload/$claimId',
      data: formData,
    );
    return response.data['url'] as String;
  }
}
