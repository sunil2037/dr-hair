/// Classification status for an uploaded scalp or hair photo.
enum HairDetectionStatus {
  analyzing,
  hairDetected,
  notHair,
  lowClarity,
}

/// Analysis result for an uploaded hair/scalp photo.
class HairPhotoAnalysis {
  final String label;
  final String photoPath;
  final HairDetectionStatus status;
  final double confidence;
  final String message;
  final String details;

  const HairPhotoAnalysis({
    required this.label,
    required this.photoPath,
    required this.status,
    required this.confidence,
    required this.message,
    required this.details,
  });

  bool get isHair => status == HairDetectionStatus.hairDetected;
  bool get isAnalyzing => status == HairDetectionStatus.analyzing;
  bool get isNotHair => status == HairDetectionStatus.notHair;
  bool get isLowClarity => status == HairDetectionStatus.lowClarity;

  Map<String, dynamic> toJson() => {
    'label': label,
    'photoPath': photoPath,
    'status': status.name,
    'confidence': confidence,
    'message': message,
    'details': details,
  };

  factory HairPhotoAnalysis.fromJson(Map<String, dynamic> json) {
    return HairPhotoAnalysis(
      label: json['label'] as String? ?? 'Scalp',
      photoPath: json['photoPath'] as String? ?? '',
      status: HairDetectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HairDetectionStatus.hairDetected,
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.85,
      message: json['message'] as String? ?? '',
      details: json['details'] as String? ?? '',
    );
  }
}

