import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:dr_hair/core/routes/route_names.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  static const MethodChannel _nativeChannel =
      MethodChannel('com.drhair.app/notifications');

  /// Displays a heads-up alert in Android system notification drawer when app is in foreground.
  static Future<void> showForegroundSystemNotification({
    required String title,
    required String body,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _nativeChannel.invokeMethod('showNotification', {
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('Could not display native foreground notification: $e');
    }
  }

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
        provisional: false,
      );
      debugPrint(
        '🔔 [FCM] Notification authorization status: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          '⚠️ [FCM] Notification permission was explicitly denied on device.',
        );
        return null;
      }

      if (kIsWeb && (webVapidKey == null || webVapidKey.isEmpty)) {
        return null;
      }

      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }

      // ignore: deprecated_member_use
      final token = await _messaging.getToken(vapidKey: webVapidKey);
      debugPrint('🔔 [FCM] Device token obtained: $token');
      return token;
    } catch (e) {
      debugPrint('⚠️ [FCM] requestPermission error: $e');
      return null;
    }
  }

  static StreamSubscription<String>? _tokenRefreshSubscription;

  /// Synchronizes device token with the backend API.
  static Future<void> syncDeviceTokenWithBackend({String? accessToken}) async {
    if (isTesting) return;

    try {
      final token = await requestPermissionAndGetToken();
      if (token == null || token.trim().isEmpty) {
        debugPrint('⚠️ [FCM] Could not obtain device token.');
        return;
      }

      final authToken = accessToken ?? await SecureSessionStore().readToken();
      final headers = <String, String>{};
      if (authToken != null && authToken.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${authToken.trim()}';
      }

      final options = Options(headers: headers);

      final response = await _dio.post(
        ApiEndpoints.notificationDeviceTokens,
        data: {'token': token.trim(), 'platform': _currentPlatformName},
        options: options,
      );
      debugPrint(
        '🔔 [FCM] Device token synced with backend status: ${response.statusCode}',
      );

      // Listen for background token rotations (cancelling any prior subscription)
      await _tokenRefreshSubscription?.cancel();
      // ignore: deprecated_member_use
      _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((newToken) async {
        if (newToken.trim().isNotEmpty) {
          try {
            final dynamicAuth = await SecureSessionStore().readToken();
            final refreshHeaders = <String, String>{};
            if (dynamicAuth != null && dynamicAuth.trim().isNotEmpty) {
              refreshHeaders['Authorization'] = 'Bearer ${dynamicAuth.trim()}';
            }
            await _dio.post(
              ApiEndpoints.notificationDeviceTokens,
              data: {
                'token': newToken.trim(),
                'platform': _currentPlatformName,
              },
              options: Options(headers: refreshHeaders),
            );
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint('FirebasePushService syncDeviceTokenWithBackend error: $e');
    }
  }

  /// Unregisters device token on user logout and cleans device token from FCM.
  static Future<void> unregisterDeviceToken({String? accessToken}) async {
    if (isTesting) return;

    try {
      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;

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
      try {
        // ignore: deprecated_member_use
        await _messaging.deleteToken();
      } catch (_) {}
    } catch (e) {
      debugPrint('FirebasePushService unregisterDeviceToken error: $e');
    }
  }

  /// Parses remote message data payload and returns target deep link location.
  static String? resolveMessageLocation(RemoteMessage message) {
    if (message.data.isEmpty) return null;
    final dest = AppDestination.fromNotificationData(message.data);
    final target = dest.location ?? dest.fallbackLocation;
    return AppDestination.resolveSafeLocation(
      target,
      fallback: RouteNames.notifications,
    );
  }

  /// Extracts image URL from remote message if provided in notification or data payload.
  static String? resolveMessageImageUrl(RemoteMessage message) {
    final notificationImage =
        message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl;
    if (notificationImage != null && notificationImage.trim().isNotEmpty) {
      return notificationImage.trim();
    }
    final dataUrl =
        message.data['image_url'] ??
        message.data['imageUrl'] ??
        message.data['image'];
    if (dataUrl is String && dataUrl.trim().isNotEmpty) {
      return dataUrl.trim();
    }
    return null;
  }
}
