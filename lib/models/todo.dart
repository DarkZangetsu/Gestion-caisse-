/*import 'package:flutter/material.dart';

// Énumération Priority avec méthodes d'extension
enum Priority {
  low,
  medium,
  high;

  // Convertir Priority en String pour JSON
  String toJson() => name;

  // Convertir String en Priority
  static Priority fromJson(String? json) {
    switch (json?.toLowerCase()) {
      case 'high':
        return Priority.high;
      case 'low':
        return Priority.low;
      default:
        return Priority.medium;
    }
  }

  // Obtenir l'icône associée à la priorité
  IconData get icon {
    switch (this) {
      case Priority.high:
        return Icons.priority_high;
      case Priority.medium:
        return Icons.remove;
      case Priority.low:
        return Icons.arrow_downward;
    }
  }

  // Obtenir la couleur associée à la priorité
  Color get color {
    switch (this) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.blue;
    }
  }

  // Obtenir le libellé en français
  String get label {
    switch (this) {
      case Priority.high:
        return 'Haute';
      case Priority.medium:
        return 'Moyenne';
      case Priority.low:
        return 'Basse';
    }
  }
}

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
  final TimeOfDay? notificationTime;
  final Priority priority;

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
    this.notificationTime,
    this.priority = Priority.medium,
  });

  // Constructeur depuis JSON
  factory Todo.fromJson(Map<String, dynamic> json) {
    // Convertir le TimeOfDay depuis JSON si présent
    TimeOfDay? notifTime;
    if (json['notification_time'] != null) {
      final timeParts = json['notification_time'].split(':');
      notifTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return Todo(
      id: json['id'],
      accountId: json['account_id'],
      chantierId: json['chantier_id'],
      personnelId: json['personnel_id'],
      description: json['description'],
      estimatedAmount: json['estimated_amount'] != null
          ? double.parse(json['estimated_amount'].toString())
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paymentMethodId: json['payment_method_id'],
      paymentTypeId: json['payment_type_id'],
      completed: json['completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notificationTime: notifTime,
      priority: Priority.fromJson(json['priority']),
    );
  }

  // Convertir en JSON
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
      'notification_time': notificationTime != null
          ? '${notificationTime!.hour.toString().padLeft(2, '0')}:${notificationTime!.minute.toString().padLeft(2, '0')}'
          : null,
      'priority': priority.toJson(),
    };
  }

  // Copier avec modifications
  Todo copyWith({
    String? id,
    String? accountId,
    String? chantierId,
    String? personnelId,
    String? description,
    double? estimatedAmount,
    DateTime? dueDate,
    String? paymentMethodId,
    String? paymentTypeId,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    TimeOfDay? notificationTime,
    Priority? priority,
  }) {
    return Todo(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      chantierId: chantierId ?? this.chantierId,
      personnelId: personnelId ?? this.personnelId,
      description: description ?? this.description,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      dueDate: dueDate ?? this.dueDate,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationTime: notificationTime ?? this.notificationTime,
      priority: priority ?? this.priority,
    );
  }

  // Méthodes utilitaires
  bool get isOverdue {
    if (dueDate == null) return false;
    return !completed && dueDate!.isBefore(DateTime.now());
  }

  bool get needsNotification {
    return !completed && dueDate != null && notificationTime != null;
  }

  bool get isUrgent {
    return priority == Priority.high && !completed;
  }

  // Pour la comparaison et le tri
  int compareTo(Todo other) {
    // D'abord par priorité
    if (priority != other.priority) {
      return other.priority.index - priority.index;
    }
    // Ensuite par date d'échéance
    if (dueDate != null && other.dueDate != null) {
      return dueDate!.compareTo(other.dueDate!);
    }
    // Les tâches sans date d'échéance en dernier
    if (dueDate == null && other.dueDate != null) return 1;
    if (dueDate != null && other.dueDate == null) return -1;
    // Enfin par date de création
    return createdAt.compareTo(other.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          accountId == other.accountId &&
          description == other.description &&
          priority == other.priority;

  @override
  int get hashCode =>
      id.hashCode ^
      accountId.hashCode ^
      description.hashCode ^
      priority.hashCode;
}
*/

import 'package:flutter/material.dart';

// Énumération Priority avec méthodes d'extension
enum TodoPriority {
  low,
  medium,
  high;

  // Convertir Priority en String pour JSON
  String toJson() => name;

  // Convertir String en Priority
  static TodoPriority fromJson(String? json) {
    switch (json?.toLowerCase()) {
      case 'high':
        return TodoPriority.high;
      case 'low':
        return TodoPriority.low;
      default:
        return TodoPriority.medium;
    }
  }

  // Obtenir l'icône associée à la priorité
  IconData get icon {
    switch (this) {
      case TodoPriority.high:
        return Icons.priority_high;
      case TodoPriority.medium:
        return Icons.remove;
      case TodoPriority.low:
        return Icons.arrow_downward;
    }
  }

  // Obtenir la couleur associée à la priorité
  Color get color {
    switch (this) {
      case TodoPriority.high:
        return Colors.red;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.low:
        return Colors.blue;
    }
  }

  // Obtenir le libellé en français
  String get label {
    switch (this) {
      case TodoPriority.high:
        return 'Haute';
      case TodoPriority.medium:
        return 'Moyenne';
      case TodoPriority.low:
        return 'Basse';
    }
  }
}

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
  final TimeOfDay? notificationTime;
  final TodoPriority priority;

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
    this.notificationTime,
    this.priority = TodoPriority.medium,
  });

  // Constructeur depuis JSON
  factory Todo.fromJson(Map<String, dynamic> json) {
    // Convertir le TimeOfDay depuis JSON si présent
    TimeOfDay? notifTime;
    if (json['notification_time'] != null) {
      final timeParts = json['notification_time'].split(':');
      notifTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return Todo(
      id: json['id'],
      accountId: json['account_id'],
      chantierId: json['chantier_id'],
      personnelId: json['personnel_id'],
      description: json['description'],
      estimatedAmount: json['estimated_amount'] != null
          ? double.parse(json['estimated_amount'].toString())
          : null,
      dueDate:
          json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      paymentMethodId: json['payment_method_id'],
      paymentTypeId: json['payment_type_id'],
      completed: json['completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      notificationTime: notifTime,
      priority: TodoPriority.fromJson(json['priority']),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson({bool forDatabase = false}) {
    final json = {
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

    // Add priority and notification_time only when not saving to database
    if (!forDatabase) {
      json['priority'] = priority.toJson();
      if (notificationTime != null) {
        json['notification_time'] =
            '${notificationTime!.hour.toString().padLeft(2, '0')}:${notificationTime!.minute.toString().padLeft(2, '0')}';
      }
    }

    return json;
  }

  // Copier avec modifications
  Todo copyWith({
    String? id,
    String? accountId,
    String? chantierId,
    String? personnelId,
    String? description,
    double? estimatedAmount,
    DateTime? dueDate,
    String? paymentMethodId,
    String? paymentTypeId,
    bool? completed,
    DateTime? createdAt,
    DateTime? updatedAt,
    TimeOfDay? notificationTime,
    TodoPriority? priority,
  }) {
    return Todo(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      chantierId: chantierId ?? this.chantierId,
      personnelId: personnelId ?? this.personnelId,
      description: description ?? this.description,
      estimatedAmount: estimatedAmount ?? this.estimatedAmount,
      dueDate: dueDate ?? this.dueDate,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentTypeId: paymentTypeId ?? this.paymentTypeId,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificationTime: notificationTime ?? this.notificationTime,
      priority: priority ?? this.priority,
    );
  }

  // Méthodes utilitaires
  bool get isOverdue {
    if (dueDate == null) return false;
    return !completed && dueDate!.isBefore(DateTime.now());
  }

  bool get needsNotification {
    return !completed && dueDate != null && notificationTime != null;
  }

  bool get isUrgent {
    return priority == TodoPriority.high && !completed;
  }

  // Pour la comparaison et le tri
  int compareTo(Todo other) {
    // D'abord par priorité
    if (priority != other.priority) {
      return other.priority.index - priority.index;
    }
    // Ensuite par date d'échéance
    if (dueDate != null && other.dueDate != null) {
      return dueDate!.compareTo(other.dueDate!);
    }
    // Les tâches sans date d'échéance en dernier
    if (dueDate == null && other.dueDate != null) return 1;
    if (dueDate != null && other.dueDate == null) return -1;
    // Enfin par date de création
    return createdAt.compareTo(other.createdAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Todo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          accountId == other.accountId &&
          description == other.description &&
          priority == other.priority;

  @override
  int get hashCode =>
      id.hashCode ^
      accountId.hashCode ^
      description.hashCode ^
      priority.hashCode;
}
