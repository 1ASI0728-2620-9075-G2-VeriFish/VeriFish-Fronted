import '../config/api_config.dart';
import '../domain/notification.dart';
import 'http_client.dart';

Future<List<AppNotification>> getNotifications(int userId) async {
  final res = await httpClient.get(ApiEndpoints.notifications(userId));
  final list = res.data as List? ?? [];
  return list
      .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
      .toList();
}

Future<void> markAllRead(int userId) async {
  await httpClient.patch(ApiEndpoints.markNotificationsRead(userId));
}
