class DonationModel {
  final String id;
  final String donorName;
  final String donorPhone;
  final String type;
  final String amount;
  final String notes;
  final String locationText;
  final String status;
  final String photoUrl;
  final DateTime createdAt;

  DonationModel({
    required this.id,
    required this.donorName,
    required this.donorPhone,
    required this.type,
    required this.amount,
    required this.notes,
    required this.locationText,
    required this.status,
    required this.photoUrl,
    required this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['_id'] ?? '',
      donorName: json['donorName'] ?? '',
      donorPhone: json['donorPhone'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? '',
      notes: json['notes'] ?? '',
      locationText: json['locationText'] ?? '',
      status: json['status'] ?? 'available',
      photoUrl: json['photoUrl'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
