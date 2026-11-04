import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../firebase_options.dart';
import '../constants/api_endpoints.dart';
import '../network/dio_client.dart';
import '../routes/app_destination.dart';
import '../storage/secure_session_store.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

/// Firebase Cloud Messaging setup, token synchronization, and dynamic deep-link routing.
class FirebasePushService {
  FirebasePushService._();

  static bool get isTesting {
    if (const bool.fromEnvironment('flutter.test')) return true;
    if (!kIsWeb &&
        (Platform.environment.containsKey('FLUTTER_TEST') ||
            Platform.environment.containsKey('DART_UNIT_TEST'))) {
      return true;
    }
    try {
      final String runtime = WidgetsBinding.instance.runtimeType.toString();
      if (runtime.contains('Test')) return true;
    } catch (_) {
      return true;
    }
    return false;
  }

  static FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  static Dio get _dio => DioClient(baseUrl: ApiEndpoints.backendBaseUrl).dio;

  static String get _currentPlatformName {
    if (kIsWeb) return 'web';
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    return 'android';
  }

  static Future<void> initialize() async {
    if (isTesting) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // iOS needs explicit foreground presentation configuration
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('FirebasePushService initialize error: $e');
    }
  }

  static Stream<RemoteMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage;

  static Stream<RemoteMessage> get notificationTapMessages =>
      FirebaseMessaging.onMessageOpenedApp;

  static Future<RemoteMessage?> get initialNotificationMessage =>
      _messaging.getInitialMessage();

  // ignore: deprecated_member_use
  static Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  /// Requests notification permission and retrieves device token.
  static Future<String?> requestPermissionAndGetToken({
    String? webVapidKey,
  }) async {
    if (isTesting) return null;

    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }

      if (kIsWeb && (webVapidKey == null || webVapidKey.isEmpty)) {
        return null;
      }

      // ignore: deprecated_member_use
      return await _messaging.getToken(vapidKey: webVapidKey);
    } catch (e) {
      debugPrint('FirebasePushService requestPermission error: $e');
      return null;
    }
  }

  /// Synchronizes device token with the backend API.
  static Future<void> syncDeviceTokenWithBackend({String? accessToken}) async {
    if (isTesting) return;

    try {
      final token = await requestPermissionAndGetToken();
      if (token == null || token.trim().isEmpty) return;

      final authToken = accessToken ?? await SecureSessionStore().readToken();
      if (authToken == null || authToken.trim().isEmpty) {
        debugPrint('FirebasePushService: skip sync, patient not logged in yet.');
        return;
      }

      final options = Options(headers: {
        'Authorization': 'Bearer ${authToken.trim()}',
      });

      await _dio.post(
        ApiEndpoints.notificationDeviceTokens,
        data: {'token': token.trim(), 'platform': _currentPlatformName},
        options: options,
      );

      // Listen for background token rotations
      // ignore: deprecated_member_use
      _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.trim().isNotEmpty) {
          try {
            await _dio.post(
              ApiEndpoints.notificationDeviceTokens,
              data: {
                'token': newToken.trim(),
                'platform': _currentPlatformName,
              },
              options: options,
            );
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('FirebasePushService syncDeviceTokenWithBackend error: $e');
    }
  }

  /// Unregisters device token on user logout.
  static Future<void> unregisterDeviceToken({String? accessToken}) async {
    if (isTesting) return;

    try {
      // ignore: deprecated_member_use
      final token = await _messaging.getToken();
      if (token != null && token.trim().isNotEmpty) {
        final authToken = accessToken ?? await SecureSessionStore().readToken();
        final options = authToken != null && authToken.trim().isNotEmpty
            ? Options(headers: {'Authorization': 'Bearer ${authToken.trim()}'})
            : null;

        await _dio.delete(
          ApiEndpoints.notificationDeviceTokens,
          data: {'token': token.trim()},
          options: options,
        );
      }
    } catch (e) {
      debugPrint('FirebasePushService unregisterDeviceToken error: $e');
    }
  }

  /// Parses remote message data payload and returns target deep link location.
  static String? resolveMessageLocation(RemoteMessage message) {
    if (message.data.isEmpty) return null;
    final dest = AppDestination.fromNotificationData(message.data);
    return dest.location ?? dest.fallbackLocation;
  }
}
