import 'package:dio/dio.dart';
import '../models/claim_model.dart';
import '../models/report_model.dart';
import 'api_service.dart';

class ClaimService {
  static Future<List<ClaimModel>> fetchClaims() async {
    final response = await ApiService.client.get('/claims');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => ClaimModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<ClaimModel> fetchClaim(int id) async {
    final response = await ApiService.client.get('/claims/$id');
    return ClaimModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Submit a new claim with the after-disaster image.
  /// Returns both the created [ClaimModel] and its [ReportModel].
  static Future<({ClaimModel claim, ReportModel report})> submitClaim({
    required String disasterType,
    required String location,
    required String description,
    required String propertyType,
    required double propertyValue,
    required DateTime incidentDate,
    required String imagePath,
    double? latitude,
    double? longitude,
  }) async {
    final formData = FormData.fromMap({
      'disaster_type': disasterType,
      'location': location,
      'description': description,
      'property_type': propertyType,
      'property_value': propertyValue.toString(),
      'incident_date': incidentDate.toIso8601String(),
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      'after_image': await MultipartFile.fromFile(
        imagePath,
        filename: imagePath.split('/').last,
      ),
    });

    final response = await ApiService.client.post(
      '/claims',
      data: formData,
      options: Options(
        receiveTimeout: const Duration(seconds: 90),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    final data = response.data as Map<String, dynamic>;

    return (
      claim: ClaimModel.fromJson(data['claim'] as Map<String, dynamic>),
      report: ReportModel.fromJson(data['report'] as Map<String, dynamic>),
    );
  }
}
