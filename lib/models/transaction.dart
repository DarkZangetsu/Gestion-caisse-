class Transaction {
  final String id;
  final String accountId;
  final String? chantierId;
  final String? personnelId;
  final String paymentMethodId;
  final String paymentTypeId;
  final String? description;
  final double amount;
  final DateTime transactionDate;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    required this.accountId,
    this.chantierId,
    this.personnelId,
    required this.paymentMethodId,
    required this.paymentTypeId,
    this.description,
    required this.amount,
    required this.transactionDate,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      accountId: json['account_id'],
      chantierId: json['chantier_id'],
      personnelId: json['personnel_id'],
      paymentMethodId: json['payment_method_id'],
      paymentTypeId: json['payment_type_id'],
      description: json['description'],
      amount: double.parse(json['amount'].toString()),
      transactionDate: DateTime.parse(json['transaction_date']),
      type: json['type'],
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
      'payment_method_id': paymentMethodId,
      'payment_type_id': paymentTypeId,
      'description': description,
      'amount': amount,
      'transaction_date': transactionDate.toIso8601String(),
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}