class PaymentType {
  final String id;
  final String name;
  final String category;
  final DateTime createdAt;

  PaymentType({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
  });

  factory PaymentType.fromJson(Map<String, dynamic> json) {
    return PaymentType(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
