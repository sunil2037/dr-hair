import 'dart:async';

import 'package:dr_hair/core/routes/app_destination.dart';
import 'package:dr_hair/core/routes/route_names.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'core/notifications/firebase_push_service.dart';
import 'core/routes/app_router.dart';
import 'core/session/session_coordinator.dart';
import 'core/storage/app_local_cache.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'features/app_config/presentation/viewmodels/app_config_cubit.dart';
import 'features/auth/presentation/viewmodels/auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/appointments/presentation/clinic_appointment_cubit.dart';
import 'features/care/presentation/viewmodels/care_cubit.dart';
import 'features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'features/shop/data/datasources/cart_remote_data_source.dart';
import 'features/shop/presentation/viewmodels/cart_cubit.dart';
import 'features/shop/presentation/viewmodels/notifications_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Falls back gracefully if .env is missing or packaged differently
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebasePushService.initialize();
  await AppLocalCache.initialize();
  Bloc.observer = AppBlocObserver();

  // Render Flutter's first frame before waiting for the platform orientation
  // channel. A delayed native response should not leave the launch screen up.
  runApp(const MyApp());

  unawaited(
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).catchError((Object error) {
      debugPrint('Could not set preferred screen orientation: $error');
    }),
  );
}

class MyApp extends StatefulWidget {
  final AuthCubit? authCubit;
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  const MyApp({super.key, this.authCubit});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  late final NotificationsCubit _notificationsCubit;

  @override
  void initState() {
    super.initState();
    _notificationsCubit = NotificationsCubit()..loadNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initPushNotifications();
    });
  }

  void _initPushNotifications() {
    if (FirebasePushService.isTesting) return;

    FirebasePushService.syncDeviceTokenWithBackend();

    // Check cold-start notification message when app was terminated
    FirebasePushService.initialNotificationMessage
        .then((message) {
          if (message != null) {
            _navigateFromMessage(message);
          }
        })
        .catchError((_) {});

    // Listen to notification taps when app is in background
    _tapSubscription = FirebasePushService.notificationTapMessages.listen((
      message,
    ) {
      _navigateFromMessage(message);
    });

    // Handle incoming notification when app is in foreground (real-time in-app banner & badge update)
    _foregroundSubscription = FirebasePushService.foregroundMessages.listen((
      message,
    ) {
      final notif = message.notification;
      final title = notif?.title ?? (message.data['title'] as String?) ?? '';
      final body = notif?.body ?? (message.data['body'] as String?) ?? '';

      if (title.isNotEmpty || body.isNotEmpty) {
        // 1. Immediately bump the real-time unread badge count & prepend to active list
        _notificationsCubit.onForegroundNotificationReceived(
          title: title,
          body: body,
          id: message.messageId,
          data: message.data,
        );

        // 2. Tactile haptic feedback
        HapticFeedback.mediumImpact();

        // 3. Show floating in-app notification banner
        _showInAppNotificationBanner(
          title: title,
          body: body,
          message: message,
        );
      }
    });
  }

  void _showInAppNotificationBanner({
    required String title,
    required String body,
    required RemoteMessage message,
  }) {
    final location = FirebasePushService.resolveMessageLocation(message);
    final imageUrl = FirebasePushService.resolveMessageImageUrl(message);

    MyApp.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0F172A),
        elevation: 8,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1.0),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.bellRing,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ],
          ],
        ),
        action: location != null && location.isNotEmpty
            ? SnackBarAction(
                label: 'VIEW',
                textColor: const Color(0xFF38BDF8),
                onPressed: () => _navigateFromMessage(message),
              )
            : null,
      ),
    );
  }

  void _navigateFromMessage(RemoteMessage message) {
    try {
      final location = FirebasePushService.resolveMessageLocation(message);
      final safeLocation = AppDestination.resolveSafeLocation(
        location,
        fallback: RouteNames.notifications,
      );
      AppRouter.router.push(safeLocation);
    } catch (e) {
      debugPrint('⚠️ [FCM] Route navigation error: $e');
      try {
        AppRouter.router.go(RouteNames.notifications);
      } catch (_) {
        AppRouter.router.go(RouteNames.mainShell);
      }
    }
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _foregroundSubscription?.cancel();
    _notificationsCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: AppStrings.appName,
      scaffoldMessengerKey: MyApp.scaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          behavior: HitTestBehavior.translucent,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    return MultiBlocProvider(
      providers: [
        if (widget.authCubit != null)
          BlocProvider<AuthCubit>.value(value: widget.authCubit!)
        else
          BlocProvider<AuthCubit>(
            create: (_) =>
                AuthCubit(repository: AuthRepositoryImpl())..restoreSession(),
          ),
        BlocProvider<CartCubit>(
          create: (_) => CartCubit(
            remoteDataSource: CartRemoteDataSource(),
            syncWithBackend: true,
          ),
        ),
        BlocProvider<ClinicAppointmentCubit>(
          create: (_) => ClinicAppointmentCubit()..load(),
        ),
        BlocProvider<CareCubit>(create: (_) => CareCubit()),
        BlocProvider<NotificationsCubit>.value(value: _notificationsCubit),
        BlocProvider<AppConfigCubit>(create: (_) => AppConfigCubit()),
        BlocProvider<HairTestCubit>(
          create: (_) => HairTestCubit()..loadSavedState(),
        ),
      ],
      child: Builder(
        builder: (context) {
          SessionCoordinator.instance.attach(
            authCubit: context.read<AuthCubit>(),
            careCubit: context.read<CareCubit>(),
            cartCubit: context.read<CartCubit>(),
            appointmentCubit: context.read<ClinicAppointmentCubit>(),
            hairTestCubit: context.read<HairTestCubit>(),
          );
          return app;
        },
      ),
    );
  }
}
