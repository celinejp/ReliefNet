class VolunteerModel {
  final String id;
  final String name;
  final String phone;
  final List<String> categories;
  final String description;
  final String photoUrl;
  final String locationText;
  final String status;
  final DateTime createdAt;

  VolunteerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.categories,
    required this.description,
    required this.photoUrl,
    required this.locationText,
    required this.status,
    required this.createdAt,
  });

  factory VolunteerModel.fromJson(Map<String, dynamic> json) {
    return VolunteerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      categories: List<String>.from(json['categories'] ?? []),
      description: json['description'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      locationText: json['locationText'] ?? '',
      status: json['status'] ?? 'available',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
