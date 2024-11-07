class AppUser {
  final String id;
  final String email;
  final String password;
  final DateTime createdAt;
  final DateTime updatedAt;

  AppUser({
    required this.id,
    required this.email,
    required this.password,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'],
      email: json['email'],
      password: json['password'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}