class AppUser {
  final String id;
  final String email;
  final String? password; // Make password optional
  final DateTime createdAt;
  final DateTime? updatedAt; // Make updatedAt optional

  AppUser({
    required this.id,
    required this.email,
    this.password,
    required this.createdAt,
    this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(), // Ensure id is converted to String
      email: json['email'],
      password: json['password'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      if (password != null) 'password': password,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}