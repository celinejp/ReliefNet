class NeedModel {
  final String id;
  final String name;
  final String phone;
  final List<String> categories;
  final String urgency;
  final String description;
  final String locationText;
  final String status;
  final DateTime createdAt;

  NeedModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.categories,
    required this.urgency,
    required this.description,
    required this.locationText,
    required this.status,
    required this.createdAt,
  });

  factory NeedModel.fromJson(Map<String, dynamic> json) {
    return NeedModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      urgency: json['urgency'] ?? 'normal',
      description: json['description'] ?? '',
      locationText: json['locationText'] ?? '',
      status: json['status'] ?? 'unmatched',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
