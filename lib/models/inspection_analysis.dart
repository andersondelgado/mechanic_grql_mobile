class InspectionAnalysis {
  final String? id;
  final String? inspectionCardsFkId;
  final String? damageSeverity;
  final int? confidenceScore;
  final String? damageType;
  final double? repairEstimatedHours;
  final List<String> affectedParts;
  final List<String> partsNeeded;
  final List<String> recommendedActions;
  final String? observations;
  final String? videoUrl;
  final String? bucketFileId;
  final String? status;
  final String? createdAt;

  InspectionAnalysis({
    this.id,
    this.inspectionCardsFkId,
    this.damageSeverity,
    this.confidenceScore,
    this.damageType,
    this.repairEstimatedHours,
    this.affectedParts = const [],
    this.partsNeeded = const [],
    this.recommendedActions = const [],
    this.observations,
    this.videoUrl,
    this.bucketFileId,
    this.status,
    this.createdAt,
  });

  factory InspectionAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      }
      if (val is String) {
        if (val.startsWith('[') && val.endsWith(']')) {
          try {
            final cleaned = val.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
            return cleaned.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
          } catch (_) {}
        }
        return val.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList();
      }
      return [];
    }

    double? parseHours(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    int? parseScore(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    return InspectionAnalysis(
      id: json['id']?.toString() ?? json['analysis_id']?.toString(),
      inspectionCardsFkId: json['inspection_cards_fk_id']?.toString(),
      damageSeverity: json['damage_severity']?.toString() ?? 'moderado',
      confidenceScore: parseScore(json['confidence_score']),
      damageType: json['damage_type']?.toString(),
      repairEstimatedHours: parseHours(json['repair_estimated_hours']),
      affectedParts: parseStringList(json['affected_parts']),
      partsNeeded: parseStringList(json['parts_needed']),
      recommendedActions: parseStringList(json['recommended_actions']),
      observations: json['observations']?.toString(),
      videoUrl: json['video_url']?.toString(),
      bucketFileId: json['bucket_file_id']?.toString(),
      status: json['status']?.toString() ?? 'completado',
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (inspectionCardsFkId != null) 'inspection_cards_fk_id': inspectionCardsFkId,
    if (damageSeverity != null) 'damage_severity': damageSeverity,
    if (confidenceScore != null) 'confidence_score': confidenceScore,
    if (damageType != null) 'damage_type': damageType,
    if (repairEstimatedHours != null) 'repair_estimated_hours': repairEstimatedHours,
    'affected_parts': affectedParts,
    'parts_needed': partsNeeded,
    'recommended_actions': recommendedActions,
    if (observations != null) 'observations': observations,
    if (videoUrl != null) 'video_url': videoUrl,
    if (bucketFileId != null) 'bucket_file_id': bucketFileId,
    if (status != null) 'status': status,
    if (createdAt != null) 'created_at': createdAt,
  };
}
