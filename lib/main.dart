import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/constants/app_strings.dart';
import 'core/notifications/firebase_push_service.dart';
import 'core/routes/app_router.dart';
import 'core/session/session_coordinator.dart';
import 'core/storage/app_local_cache.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_bloc_observer.dart';
import 'features/auth/presentation/viewmodels/auth_cubit.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/appointments/presentation/clinic_appointment_cubit.dart';
import 'features/care/presentation/viewmodels/care_cubit.dart';
import 'features/hair_test/presentation/viewmodels/hair_test_cubit.dart';
import 'features/shop/data/datasources/cart_remote_data_source.dart';
import 'features/shop/presentation/viewmodels/cart_cubit.dart';
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

  const MyApp({super.key, this.authCubit});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription<RemoteMessage>? _tapSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
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

    // Handle incoming notification when app is in foreground
    _foregroundSubscription = FirebasePushService.foregroundMessages.listen((
      message,
    ) {
      final notif = message.notification;
      if (notif != null && mounted) {
        final title = notif.title ?? '';
        final body = notif.body ?? '';
        final location = FirebasePushService.resolveMessageLocation(message);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                if (body.isNotEmpty)
                  Text(
                    body,
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
            action: location != null && location.isNotEmpty
                ? SnackBarAction(
                    label: 'VIEW',
                    textColor: const Color(0xFF5EEAD4),
                    onPressed: () => _navigateFromMessage(message),
                  )
                : null,
          ),
        );
      }
    });
  }

  void _navigateFromMessage(RemoteMessage message) {
    final location = FirebasePushService.resolveMessageLocation(message);
    if (location != null && location.isNotEmpty) {
      AppRouter.router.push(location);
    }
  }

  @override
  void dispose() {
    _tapSubscription?.cancel();
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = MaterialApp.router(
      title: AppStrings.appName,
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
