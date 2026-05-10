class UnifiedAlert {
  UnifiedAlert({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.source,
    required this.syncStatus,
    this.userId,
    this.userEmail,
    this.location,
    this.severity,
    this.mode,
    this.clientAlertId,
    this.isMine = false,
  });

  final String id;
  final String? userId;
  final String? userEmail;
  final String message;
  final String? location;
  final String? severity;
  final DateTime createdAt;
  final String source; // online_cloud | offline_hub | local_cache
  final String syncStatus; // pending | synced | failed
  final String? mode; // online | offline
  final String? clientAlertId;
  final bool isMine;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'message': message,
      'location': location,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
      'source': source,
      'syncStatus': syncStatus,
      'mode': mode,
      'clientAlertId': clientAlertId,
      'isMine': isMine,
    };
  }

  factory UnifiedAlert.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = DateTime.tryParse('${json['createdAt'] ?? ''}');
    return UnifiedAlert(
      id: '${json['id'] ?? ''}',
      userId: json['userId'] as String?,
      userEmail: json['userEmail'] as String?,
      message: json['message'] as String? ?? '',
      location: json['location'] as String?,
      severity: json['severity'] as String?,
      createdAt: createdAtRaw ?? DateTime.now(),
      source: json['source'] as String? ?? 'local_cache',
      syncStatus: json['syncStatus'] as String? ?? 'synced',
      mode: json['mode'] as String?,
      clientAlertId: json['clientAlertId'] as String?,
      isMine: json['isMine'] as bool? ?? false,
    );
  }
}
