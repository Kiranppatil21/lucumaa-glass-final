import 'role.dart';

class User {
  final String id;
  final String name;
  final String? email;
  final Role role;

  const User({
    required this.id,
    required this.name,
    required this.role,
    this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final role = Role.fromApi(json['role']) ?? Role.operator;
    return User(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: (json['name'] ?? json['full_name'] ?? '').toString(),
      email: json['email']?.toString(),
      role: role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.apiValue,
      };
}
