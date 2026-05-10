import 'need_model.dart';
import 'volunteer_model.dart';

class MatchModel {
  final String id;
  final NeedModel? need;
  final VolunteerModel? volunteer;
  final String confidence;
  final String aiReason;
  final bool resolved;
  final DateTime createdAt;

  MatchModel({
    required this.id,
    required this.need,
    required this.volunteer,
    required this.confidence,
    required this.aiReason,
    required this.resolved,
    required this.createdAt,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['_id'] ?? '',
      need: json['needId'] != null && json['needId'] is Map
          ? NeedModel.fromJson(json['needId'])
          : null,
      volunteer: json['volunteerId'] != null && json['volunteerId'] is Map
          ? VolunteerModel.fromJson(json['volunteerId'])
          : null,
      confidence: json['confidence'] ?? 'medium',
      aiReason: json['aiReason'] ?? '',
      resolved: json['resolved'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
