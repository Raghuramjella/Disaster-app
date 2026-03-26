import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/report_model.dart';
import 'api_service.dart';

class ReportService {
  /// Fetches the auto-generated compensation report for a claim.
  static Future<ReportModel> fetchReport(int claimId) async {
    final response = await ApiService.client.get('/reports/$claimId');
    return ReportModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Downloads the PDF report as raw bytes.
  static Future<Uint8List> downloadPdf(int claimId) async {
    final response = await ApiService.client.get(
      '/reports/$claimId/pdf',
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }
}
