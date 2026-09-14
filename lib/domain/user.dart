class User {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String role;

  const User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == 'ADMIN';
}
