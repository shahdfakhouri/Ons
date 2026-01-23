import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static Future<void> init() async {
    await FirebaseMessaging.instance.requestPermission();
    final token = await FirebaseMessaging.instance.getToken();
    print("FCM TOKEN: $token");
  }
}
