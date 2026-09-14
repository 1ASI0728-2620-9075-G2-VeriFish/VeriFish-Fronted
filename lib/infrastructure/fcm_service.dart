import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:yaku_frontend/infrastructure/http_client.dart';
import 'package:yaku_frontend/config/api_config.dart';

class FcmService {
  static Future<void> initializeAndSendToken(int userId) async {
    try {
      final messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        final token = await messaging.getToken();
        
        if (token != null) {
          // Send to backend
          await httpClient.post(
            ApiEndpoints.deviceTokens(userId),
            data: {'fcmToken': token},
          );
        }
      }
    } catch (e) {
      print('Error initializing FCM or sending token: $e');
    }
  }
}
