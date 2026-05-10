import 'person_report_model.dart';

class PersonGroup {
  final String id;
  final List<PersonReport> reports;
  final String confidence;
  final String aiReason;
  final String representativeName;
  final String highestEmergency;
  final bool resolved;
  final DateTime? createdAt;

  PersonGroup({
    required this.id,
    required this.reports,
    required this.confidence,
    required this.aiReason,
    required this.representativeName,
    required this.highestEmergency,
    required this.resolved,
    required this.createdAt,
  });

  factory PersonGroup.fromJson(Map<String, dynamic> json) {
    final raw = json['reportIds'];
    final reports = <PersonReport>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          reports.add(PersonReport.fromJson(item));
        }
      }
    }
    return PersonGroup(
      id: json['_id']?.toString() ?? '',
      reports: reports,
      confidence: json['confidence']?.toString() ?? 'medium',
      aiReason: json['aiReason']?.toString() ?? '',
      representativeName:
          json['representativeName']?.toString() ?? 'Unknown Person',
      highestEmergency: json['highestEmergency']?.toString() ?? 'unknown',
      resolved: json['resolved'] == true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
