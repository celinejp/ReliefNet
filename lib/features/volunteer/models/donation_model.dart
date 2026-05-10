class DonationModel {
  final String id;
  final String donorName;
  final String donorPhone;
  final String type;
  final String amount;
  final String locationText;
  final String status;
  final DateTime createdAt;

  DonationModel({
    required this.id,
    required this.donorName,
    required this.donorPhone,
    required this.type,
    required this.amount,
    required this.locationText,
    required this.status,
    required this.createdAt,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    return DonationModel(
      id: json['_id'] ?? '',
      donorName: json['donorName'] ?? '',
      donorPhone: json['donorPhone'] ?? '',
      type: json['type'] ?? '',
      amount: json['amount'] ?? '',
      locationText: json['locationText'] ?? '',
      status: json['status'] ?? 'available',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}
