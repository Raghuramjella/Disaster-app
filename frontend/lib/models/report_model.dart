class ReportModel {
  final int id;
  final int claimId;
  final double similarityScore;
  final String damageTier;
  final double lossPercentage;
  final double compensationAmount;
  final String? pdfUrl;
  final DateTime generatedAt;
  // Satellite imagery
  final String? satelliteBeforeUrl;
  final String? satelliteAfterUrl;
  // Photo authenticity
  final double? authenticityScore;
  final bool? photoVerified;

  const ReportModel({
    required this.id,
    required this.claimId,
    required this.similarityScore,
    required this.damageTier,
    required this.lossPercentage,
    required this.compensationAmount,
    this.pdfUrl,
    required this.generatedAt,
    this.satelliteBeforeUrl,
    this.satelliteAfterUrl,
    this.authenticityScore,
    this.photoVerified,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) => ReportModel(
        id: json['id'] as int,
        claimId: json['claim_id'] as int,
        similarityScore: (json['similarity_score'] as num).toDouble(),
        damageTier: json['damage_tier'] as String,
        lossPercentage: (json['loss_percentage'] as num).toDouble(),
        compensationAmount: (json['compensation_amount'] as num).toDouble(),
        pdfUrl: json['pdf_url'] as String?,
        generatedAt: DateTime.parse(json['generated_at'] as String),
        satelliteBeforeUrl: json['satellite_before_url'] as String?,
        satelliteAfterUrl: json['satellite_after_url'] as String?,
        authenticityScore: json['authenticity_score'] == null
            ? null
            : (json['authenticity_score'] as num).toDouble(),
        photoVerified: json['photo_verified'] as bool?,
      );
}
