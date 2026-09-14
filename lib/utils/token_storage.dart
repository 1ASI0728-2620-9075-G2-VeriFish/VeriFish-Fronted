import 'package:shared_preferences/shared_preferences.dart';

const _keyToken = 'yaku_access_token';
const _keyUserId = 'yaku_user_id';
const _keyUsername = 'yaku_username';
const _keyFirstName = 'yaku_first_name';
const _keyLastName = 'yaku_last_name';
const _keyEmail = 'yaku_email';
const _keyRole = 'yaku_role';

class TokenStorage {
  static Future<void> saveSession({
    required String token,
    required int userId,
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUsername, username);
    await prefs.setString(_keyFirstName, firstName);
    await prefs.setString(_keyLastName, lastName);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyRole, role);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }

  static Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString(_keyUsername) ?? '',
      'firstName': prefs.getString(_keyFirstName) ?? '',
      'lastName': prefs.getString(_keyLastName) ?? '',
      'email': prefs.getString(_keyEmail) ?? '',
      'role': prefs.getString(_keyRole) ?? '',
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
