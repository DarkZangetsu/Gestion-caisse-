import 'package:flutter/material.dart';

class Chantier {
  final String id;
  final String userId;
  final String name;
  final double? budgetMax;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? color;

  Chantier({
    required this.id,
    required this.userId,
    required this.name,
    this.budgetMax,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
    this.color,
  });

  factory Chantier.fromJson(Map<String, dynamic> json) {
    return Chantier(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      budgetMax: json['budget_max'] != null ? double.parse(json['budget_max'].toString()) : null,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      color: json['color'] != null ? int.parse(json['color'].toString()) : null,
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'color': color,
    };
  }

  // Helper method to convert to Color object when needed
  Color? get colorValue => color != null ? Color(color!) : null;

  // Helper method to set color from Color object
  Chantier copyWith({Color? newColor}) {
    return Chantier(
      id: id,
      userId: userId,
      name: name,
      budgetMax: budgetMax,
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
      color: newColor?.value,
    );
  }
}