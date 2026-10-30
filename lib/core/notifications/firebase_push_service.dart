import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

/// Firebase Cloud Messaging setup and the app-facing notification streams.
class FirebasePushService {
  FirebasePushService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // iOS needs an explicit setting to present notification payloads while
    // the app is open. Android foreground messages remain available through
    // [foregroundMessages] for the UI to display.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  static Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  static Stream<RemoteMessage> get notificationTapMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  static Future<RemoteMessage?> get initialNotificationMessage =>
      _messaging.getInitialMessage();

  static Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  /// Call from a user-initiated notification setting or onboarding step.
  /// The token is returned to the caller and is never logged by this service.
  static Future<String?> requestPermissionAndGetToken({
    String? webVapidKey,
  }) async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    if (kIsWeb && (webVapidKey == null || webVapidKey.isEmpty)) {
      throw StateError(
        'Web push requires a Firebase Web Push certificate VAPID key.',
      );
    }

    return _messaging.getToken(vapidKey: webVapidKey);
  }
}
