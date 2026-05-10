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
    this.auth0UserId,
    this.userEmail,
    this.guestMode,
    this.location,
    this.mode,
    this.source,
    this.syncStatus,
    this.responderStatus,
    this.clientAlertId,
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

  final String? auth0UserId;
  final String? userEmail;
  final bool? guestMode;
  final String? location;
  final String? mode;
  final String? source;
  final String? syncStatus;
  final String? responderStatus;
  final String? clientAlertId;

  factory CloudIncident.fromJson(Map<String, dynamic> json) {
    DateTime? parseTs(dynamic v) {
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final rawId = json['_id'];
    final String id;
    if (rawId is String) {
      id = rawId;
    } else if (rawId is Map && rawId[r'$oid'] is String) {
      id = rawId[r'$oid'] as String;
    } else {
      id = rawId?.toString() ?? '';
    }

    final guestRaw = json['guestMode'];

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
      auth0UserId: json['auth0UserId'] as String?,
      userEmail: json['userEmail'] as String?,
      guestMode: guestRaw is bool ? guestRaw : null,
      location: json['location'] as String?,
      mode: json['mode'] as String?,
      source: json['source'] as String?,
      syncStatus: json['syncStatus'] as String?,
      responderStatus: json['responderStatus'] as String?,
      clientAlertId: json['clientAlertId'] as String?,
    );
  }
}
