class Personnel {
  final String id;
  final String userId;
  final String name;
  final String? role;
  final String? contact;
  final double? salaireMax;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Personnel({
    required this.id,
    required this.userId,
    required this.name,
    this.role,
    this.contact,
    this.salaireMax,
    this.createdAt,
    this.updatedAt,
  });

  factory Personnel.fromJson(Map<String, dynamic> json) {
    return Personnel(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      role: json['role'],
      contact: json['contact'],
      salaireMax: json['salaire_max'] != null ? double.parse(json['salaire_max'].toString()) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'role': role,
      'contact': contact,
      'salaire_max': salaireMax,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
