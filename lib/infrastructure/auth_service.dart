import 'dart:convert';
import '../config/api_config.dart';
import '../domain/user.dart';
import '../utils/token_storage.dart';
import 'http_client.dart';

Map<String, dynamic> _decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = parts[1];
    final normalized = base64.normalize(payload);
    return jsonDecode(utf8.decode(base64.decode(normalized))) as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

String _mapRole(dynamic raw) {
  final r = raw is List ? (raw.isNotEmpty ? raw[0].toString() : '') : raw?.toString() ?? '';
  if (r.contains('ADMIN')) return 'ADMIN';
  if (r.contains('OPERATOR')) return 'OPERATOR';
  return 'ADMIN';
}

Future<Map<String, dynamic>> _fetchProfile(String username) async {
  try {
    final res = await httpClient.get(
      ApiEndpoints.usersByUsername,
      queryParameters: {'username': username},
    );
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return {};
  }
}

Future<User> login(String username, String password) async {
  final res = await httpClient.post(ApiEndpoints.signin, data: {
    'username': username,
    'password': password,
  });

  final data = res.data as Map<String, dynamic>;
  final token = (data['token'] ?? '') as String;

  // user fields are nested under data['user']
  final user = (data['user'] as Map<String, dynamic>?) ?? {};
  final id = int.tryParse((user['id'] ?? 0).toString()) ?? 0;
  final role = _mapRole(user['roles'] ?? user['role']);
  final firstName = (user['firstName'] ?? '').toString();
  final lastName = (user['lastName'] ?? '').toString();
  final email = (user['email'] ?? '').toString();

  await TokenStorage.saveSession(
    token: token,
    userId: id,
    username: username,
    firstName: firstName,
    lastName: lastName,
    email: email,
    role: role,
  );

  return User(id: id, username: username, firstName: firstName, lastName: lastName, email: email, role: role);
}

Future<User> register({
  required String username,
  required String firstName,
  required String lastName,
  required String email,
  required String password,
  required String role,
  String? farmToken,
}) async {
  final body = {
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'email': email,
    'password': password,
    'role': role,
    if (farmToken != null && farmToken.isNotEmpty) 'farmToken': farmToken,
  };

  // Signup only returns a plain string (201), not a JWT.
  // Auto-login after success to get the real token.
  await httpClient.post(ApiEndpoints.signup, data: body);
  return login(username, password);
}

Future<void> changePassword({required int userId, required String currentPassword, required String newPassword}) async {
  await httpClient.patch(ApiEndpoints.changePassword(userId), data: {
    'currentPassword': currentPassword,
    'newPassword': newPassword,
  });
}

Future<User> getUserById(int id) async {
  final res = await httpClient.get(ApiEndpoints.userById(id));
  final data = res.data as Map<String, dynamic>;
  final roles = data['roles'] as List?;
  return User(
    id: data['id'] ?? id,
    username: data['username'] ?? '',
    firstName: data['firstName'] ?? '',
    lastName: data['lastName'] ?? '',
    email: data['email'] ?? '',
    role: roles != null && roles.isNotEmpty ? roles[0].toString() : (data['role']?.toString() ?? ''),
  );
}
