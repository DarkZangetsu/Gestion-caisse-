class PaymentMethod {
  final String id;
  final String name;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
