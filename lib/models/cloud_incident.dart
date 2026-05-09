class CloudIncident {
  CloudIncident({
    required this.id,
    required this.rawMessage,
    required this.severity,
    required this.category,
    required this.summary,
    required this.processingStatus,
    required this.aiError,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String rawMessage;
  final String? severity;
  final String category;
  final String summary;
  final String processingStatus;
  final String? aiError;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CloudIncident.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final id = json['_id']?.toString() ?? '';

    return CloudIncident(
      id: id,
      rawMessage: json['rawMessage'] as String? ?? '',
      severity: json['severity'] as String?,
      category: json['category'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      processingStatus: json['processingStatus'] as String? ?? 'pending',
      aiError: json['aiError'] as String?,
      createdAt: parseTs(json['createdAt']),
      updatedAt: parseTs(json['updatedAt']),
    );
  }
}
