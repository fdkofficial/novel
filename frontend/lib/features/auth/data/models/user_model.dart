class AuthUser {
  final String id;
  final String email;
  final String? username;
  final String? role;

  AuthUser({
    required this.id,
    required this.email,
    this.username,
    this.role,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'],
      email: json['email'],
      username: json['username'],
      role: json['role'],
    );
  }
}
