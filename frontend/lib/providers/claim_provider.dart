import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/claim_model.dart';
import '../models/report_model.dart';
import '../services/claim_service.dart';
import '../services/report_service.dart';

class ClaimState {
  final List<ClaimModel> claims;
  final Map<int, ReportModel> reports;
  final bool isLoading;
  final String? error;

  const ClaimState({
    this.claims = const [],
    this.reports = const {},
    this.isLoading = false,
    this.error,
  });

  int get verifiedCount =>
      claims.where((c) => c.status == 'verified').length;

  double get totalCompensation =>
      reports.values.fold(0.0, (sum, r) => sum + r.compensationAmount);

  ClaimState copyWith({
    List<ClaimModel>? claims,
    Map<int, ReportModel>? reports,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ClaimState(
      claims: claims ?? this.claims,
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ClaimNotifier extends Notifier<ClaimState> {
  @override
  ClaimState build() {
    Future.microtask(loadClaims);
    return const ClaimState(isLoading: true);
  }

  Future<void> loadClaims() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final claims = await ClaimService.fetchClaims();

      final reportFutures = claims
          .where((c) => c.status == 'verified')
          .map((c) async {
        try {
          final r = await ReportService.fetchReport(c.id);
          return MapEntry(c.id, r);
        } catch (_) {
          return null;
        }
      });

      final reportEntries = await Future.wait(reportFutures);
      final reports = Map<int, ReportModel>.fromEntries(
        reportEntries.whereType<MapEntry<int, ReportModel>>(),
      );

      state = state.copyWith(claims: claims, reports: reports, isLoading: false);
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _errorMessage(e),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ReportModel> submitClaim({
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
    final result = await ClaimService.submitClaim(
      disasterType: disasterType,
      location: location,
      description: description,
      propertyType: propertyType,
      propertyValue: propertyValue,
      incidentDate: incidentDate,
      imagePath: imagePath,
      latitude: latitude,
      longitude: longitude,
    );

    state = state.copyWith(
      claims: [...state.claims, result.claim],
      reports: {...state.reports, result.claim.id: result.report},
    );

    return result.report;
  }

  ReportModel? getReport(int claimId) => state.reports[claimId];

  String _errorMessage(DioException e) {
    if (e.response?.data?['detail'] != null) {
      return e.response!.data['detail'].toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    return e.message ?? 'Something went wrong';
  }
}

final claimProvider =
    NotifierProvider<ClaimNotifier, ClaimState>(ClaimNotifier.new);
