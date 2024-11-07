class Todo {
  final String id;
  final String accountId;
  final String? chantierId;
  final String? personnelId;
  final String description;
  final double? estimatedAmount;
  final DateTime? dueDate;
  final String? paymentMethodId;
  final String? paymentTypeId;
  final bool completed;
  final DateTime createdAt;
  final DateTime updatedAt;

  Todo({
    required this.id,
    required this.accountId,
    this.chantierId,
    this.personnelId,
    required this.description,
    this.estimatedAmount,
    this.dueDate,
    this.paymentMethodId,
    this.paymentTypeId,
    required this.completed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      accountId: json['account_id'],
      chantierId: json['chantier_id'],
      personnelId: json['personnel_id'],
      description: json['description'],
      estimatedAmount: json['estimated_amount'] != null ? double.parse(json['estimated_amount'].toString()) : null,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paymentMethodId: json['payment_method_id'],
      paymentTypeId: json['payment_type_id'],
      completed: json['completed'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'account_id': accountId,
      'chantier_id': chantierId,
      'personnel_id': personnelId,
      'description': description,
      'estimated_amount': estimatedAmount,
      'due_date': dueDate?.toIso8601String(),
      'payment_method_id': paymentMethodId,
      'payment_type_id': paymentTypeId,
      'completed': completed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}