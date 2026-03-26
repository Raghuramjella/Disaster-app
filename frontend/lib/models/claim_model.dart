class ClaimModel {
  final int id;
  final String disasterType;
  final String location;
  final String description;
  final String status; // 'pending' | 'processing' | 'verified'
  final DateTime submittedAt;
  final String? afterImageUrl;

  const ClaimModel({
    required this.id,
    required this.disasterType,
    required this.location,
    required this.description,
    required this.status,
    required this.submittedAt,
    this.afterImageUrl,
  });

  factory ClaimModel.fromJson(Map<String, dynamic> json) => ClaimModel(
        id: json['id'] as int,
        disasterType: json['disaster_type'] as String,
        location: json['location'] as String,
        description: json['description'] as String,
        status: json['status'] as String,
        submittedAt: DateTime.parse(json['submitted_at'] as String),
        afterImageUrl: json['after_image_url'] as String?,
      );
}
