class PersonReport {
  final String id;
  final String reportType;
  final String name;
  final String approximateAge;
  final String gender;
  final String descriptionText;
  final bool isInjured;
  final bool isUnconscious;
  final String emergencyLevel;
  final String locationText;
  final double? lat;
  final double? lng;
  final DateTime? lastSeenAt;
  final String photoUrl;
  final String reporterName;
  final String reporterPhone;
  final bool resolved;
  final String? groupId;
  final DateTime? createdAt;

  PersonReport({
    required this.id,
    required this.reportType,
    required this.name,
    required this.approximateAge,
    required this.gender,
    required this.descriptionText,
    required this.isInjured,
    required this.isUnconscious,
    required this.emergencyLevel,
    required this.locationText,
    required this.lat,
    required this.lng,
    required this.lastSeenAt,
    required this.photoUrl,
    required this.reporterName,
    required this.reporterPhone,
    required this.resolved,
    required this.groupId,
    required this.createdAt,
  });

  factory PersonReport.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as Map<String, dynamic>?;
    return PersonReport(
      id: json['_id']?.toString() ?? '',
      reportType: json['reportType']?.toString() ?? 'looking',
      name: json['name']?.toString() ?? 'Unknown',
      approximateAge: json['approximateAge']?.toString() ?? '',
      gender: json['gender']?.toString() ?? 'unknown',
      descriptionText: json['descriptionText']?.toString() ?? '',
      isInjured: json['isInjured'] == true,
      isUnconscious: json['isUnconscious'] == true,
      emergencyLevel: json['emergencyLevel']?.toString() ?? 'unknown',
      locationText: json['locationText']?.toString() ?? '',
      lat: (coords?['lat'] as num?)?.toDouble(),
      lng: (coords?['lng'] as num?)?.toDouble(),
      lastSeenAt: _parseDate(json['lastSeenAt']),
      photoUrl: json['photoUrl']?.toString() ?? '',
      reporterName: json['reporterName']?.toString() ?? '',
      reporterPhone: json['reporterPhone']?.toString() ?? '',
      resolved: json['resolved'] == true,
      groupId: json['groupId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }
}
