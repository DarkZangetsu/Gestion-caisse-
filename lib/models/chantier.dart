class Chantier {
  final String id;
  final String userId;
  final String name;
  final double? budgetMax;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chantier({
    required this.id,
    required this.userId,
    required this.name,
    this.budgetMax,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chantier.fromJson(Map<String, dynamic> json) {
    return Chantier(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      budgetMax: json['budget_max'] != null ? double.parse(json['budget_max'].toString()) : null,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'budget_max': budgetMax,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}