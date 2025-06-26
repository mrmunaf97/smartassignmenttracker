class AppUser {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'teacher'

  AppUser(
      {required this.id,
      required this.name,
      required this.email,
      required this.role});

  factory AppUser.fromMap(Map<String, dynamic> map, String id) {
    return AppUser(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'student',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
